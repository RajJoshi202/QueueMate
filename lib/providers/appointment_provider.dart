import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../services/connectivity_service.dart';
import '../core/utils.dart';

/// State class for the appointment notifier, holding both
/// the list of appointments and a loading flag.
class AppointmentState {
  final List<Appointment> appointments;
  final bool isLoading;

  const AppointmentState({
    this.appointments = const [],
    this.isLoading = false,
  });

  /// Creates a copy of this state with optional overrides.
  AppointmentState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// AppointmentNotifier manages all appointment-related state and operations.
/// Handles CRUD operations with offline-first strategy: saves to Hive first,
/// then syncs to Firestore when online.
class AppointmentNotifier extends StateNotifier<AppointmentState> {
  final HiveService _hiveService;
  final FirestoreService _firestoreService;
  final ConnectivityService _connectivityService;

  AppointmentNotifier({
    required HiveService hiveService,
    required FirestoreService firestoreService,
    required ConnectivityService connectivityService,
  })  : _hiveService = hiveService,
        _firestoreService = firestoreService,
        _connectivityService = connectivityService,
        super(const AppointmentState()) {
    _init();
  }

  /// Initializes the notifier by loading appointments from Hive,
  /// then fetching from Firestore if online and merging the results.
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);

    // Load from local Hive storage first (offline-first)
    final localAppointments = _hiveService.getAllAppointments();
    state = state.copyWith(appointments: localAppointments);

    // If online, fetch from Firestore and merge
    final online = await _connectivityService.isOnline;
    if (online) {
      try {
        final remoteAppointments =
            await _firestoreService.getAllAppointments();
        final merged = _mergeAppointments(localAppointments, remoteAppointments);
        state = state.copyWith(appointments: merged);

        // Save merged data back to Hive
        for (final a in merged) {
          await _hiveService.saveAppointment(a.copyWith(synced: true));
        }
      } catch (e) {
        print('AppointmentNotifier._init remote fetch error: $e');
      }
    }

    state = state.copyWith(isLoading: false);
  }

  /// Merges local and remote appointment lists.
  /// Remote data takes precedence for existing IDs; local-only items are preserved.
  List<Appointment> _mergeAppointments(
      List<Appointment> local, List<Appointment> remote) {
    final Map<String, Appointment> merged = {};

    // Add all remote appointments (these are the source of truth)
    for (final a in remote) {
      merged[a.id] = a.copyWith(synced: true);
    }

    // Add local-only appointments (not yet synced)
    for (final a in local) {
      if (!merged.containsKey(a.id)) {
        merged[a.id] = a;
      }
    }

    return merged.values.toList();
  }

  /// Adds a new appointment after validation.
  /// Validates: not past, slot not full, no duplicate booking.
  /// Saves to Hive first, then to Firestore if online.
  Future<void> addAppointment(Appointment appointment) async {
    final appointments = state.appointments;

    // Validation 1: Cannot book a past date/time
    if (isPastDateTime(appointment.dateTime)) {
      throw Exception('Cannot book a past date/time');
    }

    // Validation 2: Check if slot is full (max 3 per slot)
    if (isSlotFull(appointments, appointment.dateTime)) {
      throw Exception('This slot is fully booked (max $maxPerSlot)');
    }

    // Validation 3: Check for duplicate booking
    if (isDuplicateBooking(
        appointments, appointment.name, appointment.dateTime)) {
      throw Exception('You already have a booking at this time');
    }

    // Save to Hive first (offline-first, synced: false)
    var newAppointment = appointment.copyWith(synced: false);
    await _hiveService.saveAppointment(newAppointment);

    // If online, push to Firestore and mark as synced
    final online = await _connectivityService.isOnline;
    if (online) {
      try {
        await _firestoreService.saveAppointment(newAppointment);
        newAppointment = newAppointment.copyWith(synced: true);
        await _hiveService.updateAppointment(newAppointment);
      } catch (e) {
        print('AppointmentNotifier.addAppointment Firestore error: $e');
      }
    }

    // Update state with new appointment
    state = state.copyWith(
      appointments: [...state.appointments, newAppointment],
    );
  }

  /// Updates the status of an appointment by ID.
  /// Updates both local Hive storage and Firestore (if online).
  Future<void> updateStatus(String id, String newStatus) async {
    final index = state.appointments.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final updated =
        state.appointments[index].copyWith(status: newStatus, synced: false);

    // Update in Hive
    await _hiveService.updateAppointment(updated);

    // Update in Firestore if online
    final online = await _connectivityService.isOnline;
    if (online) {
      try {
        await _firestoreService.updateAppointment(updated);
        await _hiveService
            .updateAppointment(updated.copyWith(synced: true));
      } catch (e) {
        print('AppointmentNotifier.updateStatus Firestore error: $e');
      }
    }

    // Update state
    final updatedList = List<Appointment>.from(state.appointments);
    updatedList[index] = online ? updated.copyWith(synced: true) : updated;
    state = state.copyWith(appointments: updatedList);
  }

  /// Reschedules an appointment to a new date/time slot.
  /// Validates the new slot before updating.
  Future<void> rescheduleAppointment(String id, DateTime newSlot) async {
    // Validate new slot
    if (isPastDateTime(newSlot)) {
      throw Exception('Cannot reschedule to a past date/time');
    }

    if (isSlotFull(state.appointments, newSlot)) {
      throw Exception('The new slot is fully booked (max $maxPerSlot)');
    }

    final index = state.appointments.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final appointment = state.appointments[index];

    if (isDuplicateBooking(state.appointments, appointment.name, newSlot)) {
      throw Exception('You already have a booking at the new time');
    }

    final newPosition = getQueuePosition(state.appointments, newSlot);
    final updated = appointment.copyWith(
      dateTime: newSlot,
      queuePosition: newPosition,
      synced: false,
    );

    // Update in Hive
    await _hiveService.updateAppointment(updated);

    // Update in Firestore if online
    final online = await _connectivityService.isOnline;
    if (online) {
      try {
        await _firestoreService.updateAppointment(updated);
        await _hiveService
            .updateAppointment(updated.copyWith(synced: true));
      } catch (e) {
        print('AppointmentNotifier.rescheduleAppointment Firestore error: $e');
      }
    }

    final updatedList = List<Appointment>.from(state.appointments);
    updatedList[index] = online ? updated.copyWith(synced: true) : updated;
    state = state.copyWith(appointments: updatedList);
  }

  /// Cancels an appointment by setting its status to "Cancelled".
  Future<void> cancelAppointment(String id) async {
    await updateStatus(id, 'Cancelled');
  }

  /// Refreshes the appointment list from Firestore if online.
  /// Merges remote data with local unsynced appointments.
  Future<void> refreshFromFirestore() async {
    final online = await _connectivityService.isOnline;
    if (!online) return;

    state = state.copyWith(isLoading: true);
    try {
      final remoteAppointments =
          await _firestoreService.getAllAppointments();
      final localAppointments = _hiveService.getAllAppointments();
      final merged = _mergeAppointments(localAppointments, remoteAppointments);
      state = state.copyWith(appointments: merged, isLoading: false);

      // Save merged data back to Hive
      for (final a in merged) {
        await _hiveService.saveAppointment(a);
      }
    } catch (e) {
      print('AppointmentNotifier.refreshFromFirestore error: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

// ─── Riverpod Providers ──────────────────────────────────────────

/// Provides the HiveService instance.
final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

/// Provides the FirestoreService instance.
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

/// Provides the ConnectivityService instance.
final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) => ConnectivityService());

/// Provides the AppointmentNotifier with injected dependencies.
final appointmentNotifierProvider =
    StateNotifierProvider<AppointmentNotifier, AppointmentState>((ref) {
  return AppointmentNotifier(
    hiveService: ref.watch(hiveServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

/// Convenience provider to access just the appointment list.
final appointmentsProvider = Provider<List<Appointment>>((ref) {
  return ref.watch(appointmentNotifierProvider).appointments;
});

/// Provider to access the loading state.
final appointmentsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(appointmentNotifierProvider).isLoading;
});

/// Import for maxPerSlot constant used in validation messages
const int maxPerSlot = 3;
