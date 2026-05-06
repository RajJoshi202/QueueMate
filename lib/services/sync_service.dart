import 'hive_service.dart';
import 'firestore_service.dart';

/// SyncService handles synchronization between local Hive storage
/// and cloud Firestore. Pushes unsynced local appointments to the
/// cloud when connectivity is restored.
class SyncService {
  final HiveService _hiveService;
  final FirestoreService _firestoreService;

  SyncService({
    required HiveService hiveService,
    required FirestoreService firestoreService,
  })  : _hiveService = hiveService,
        _firestoreService = firestoreService;

  /// Syncs all pending (unsynced) appointments from Hive to Firestore.
  /// For each unsynced appointment:
  ///   1. Pushes it to Firestore
  ///   2. Marks it as synced in the local Hive box
  /// Returns the count of successfully synced records.
  Future<int> syncPending() async {
    final unsynced = _hiveService.getUnsyncedAppointments();
    int syncedCount = 0;

    for (final appointment in unsynced) {
      try {
        // Push to Firestore
        await _firestoreService.saveAppointment(appointment);

        // Mark as synced in Hive
        final syncedAppointment = appointment.copyWith(synced: true);
        await _hiveService.updateAppointment(syncedAppointment);

        syncedCount++;
      } catch (e) {
        print('SyncService.syncPending error for ${appointment.id}: $e');
        // Continue syncing remaining appointments even if one fails
      }
    }

    return syncedCount;
  }
}
