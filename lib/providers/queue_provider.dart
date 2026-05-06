import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import 'appointment_provider.dart';

/// QueueState holds the current queue status including the current token
/// being served and the list of today's queued appointments.
class QueueState {
  final int currentToken;
  final List<Appointment> todayQueue;

  const QueueState({
    this.currentToken = 0,
    this.todayQueue = const [],
  });

  QueueState copyWith({
    int? currentToken,
    List<Appointment>? todayQueue,
  }) {
    return QueueState(
      currentToken: currentToken ?? this.currentToken,
      todayQueue: todayQueue ?? this.todayQueue,
    );
  }
}

/// QueueNotifier manages queue operations for today's appointments.
/// Derives state from the appointment list and provides queue
/// advancement functionality.
class QueueNotifier extends StateNotifier<QueueState> {
  final Ref _ref;

  QueueNotifier(this._ref) : super(const QueueState()) {
    // Listen to appointment changes and update queue
    _ref.listen<List<Appointment>>(appointmentsProvider, (previous, next) {
      _updateQueue(next);
    });
    // Initialize with current appointments
    _updateQueue(_ref.read(appointmentsProvider));
  }

  /// Updates the queue state based on the current appointment list.
  /// Filters for today's Scheduled and In Progress appointments,
  /// sorted by queue position.
  void _updateQueue(List<Appointment> appointments) {
    final now = DateTime.now();
    final todayAppts = appointments.where((a) {
      return a.dateTime.year == now.year &&
          a.dateTime.month == now.month &&
          a.dateTime.day == now.day &&
          (a.status == 'Scheduled' || a.status == 'In Progress');
    }).toList()
      ..sort((a, b) => a.queuePosition.compareTo(b.queuePosition));

    // Current token is the queue position of the first "In Progress" appointment
    final inProgressList =
        todayAppts.where((a) => a.status == 'In Progress').toList();
    final currentToken =
        inProgressList.isNotEmpty ? inProgressList.first.queuePosition : 0;

    state = state.copyWith(
      currentToken: currentToken,
      todayQueue: todayAppts,
    );
  }

  /// Moves the queue forward:
  /// 1. Marks the current "In Progress" appointment as "Completed"
  /// 2. Sets the next "Scheduled" appointment to "In Progress"
  Future<void> moveQueueForward() async {
    final notifier = _ref.read(appointmentNotifierProvider.notifier);
    final appointments = _ref.read(appointmentsProvider);
    final now = DateTime.now();

    // Get today's appointments sorted by queue position
    final todayAppts = appointments.where((a) {
      return a.dateTime.year == now.year &&
          a.dateTime.month == now.month &&
          a.dateTime.day == now.day;
    }).toList()
      ..sort((a, b) => a.queuePosition.compareTo(b.queuePosition));

    // Complete the current "In Progress" appointment
    final inProgress =
        todayAppts.where((a) => a.status == 'In Progress').toList();
    if (inProgress.isNotEmpty) {
      await notifier.updateStatus(inProgress.first.id, 'Completed');
    }

    // Set the next "Scheduled" appointment to "In Progress"
    final scheduled =
        todayAppts.where((a) => a.status == 'Scheduled').toList();
    if (scheduled.isNotEmpty) {
      await notifier.updateStatus(scheduled.first.id, 'In Progress');
    }
  }

  /// Gets the queue position of a specific appointment by ID.
  int getUserPosition(String appointmentId) {
    final appointments = _ref.read(appointmentsProvider);
    final appointment = appointments.where((a) => a.id == appointmentId);
    if (appointment.isNotEmpty) {
      return appointment.first.queuePosition;
    }
    return 0;
  }
}

// ─── Riverpod Providers ──────────────────────────────────────────

/// Provides the QueueNotifier for queue management operations.
final queueNotifierProvider =
    StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  return QueueNotifier(ref);
});

/// Convenience provider for the current token being served.
final currentTokenProvider = Provider<int>((ref) {
  return ref.watch(queueNotifierProvider).currentToken;
});

/// Convenience provider for today's queue list.
final todayQueueProvider = Provider<List<Appointment>>((ref) {
  return ref.watch(queueNotifierProvider).todayQueue;
});
