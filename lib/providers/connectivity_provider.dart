import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import 'appointment_provider.dart';

/// StreamProvider that emits the current online/offline status.
/// Listens to connectivity changes and auto-triggers sync when
/// connectivity is restored (transitions from offline to online).
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  bool wasOffline = false;

  return connectivityService.isOnlineStream.map((isOnline) {
    // Auto-sync when connectivity is restored
    if (isOnline && wasOffline) {
      _triggerSync(ref);
    }
    wasOffline = !isOnline;
    return isOnline;
  });
});

/// Triggers the sync process when connectivity is restored.
/// Syncs pending appointments and refreshes from Firestore.
Future<void> _triggerSync(StreamProviderRef<bool> ref) async {
  try {
    final syncService = SyncService(
      hiveService: ref.read(hiveServiceProvider),
      firestoreService: ref.read(firestoreServiceProvider),
    );

    final syncedCount = await syncService.syncPending();
    if (syncedCount > 0) {
      print('Synced $syncedCount appointments to Firestore');
    }

    // Refresh appointments from Firestore
    await ref
        .read(appointmentNotifierProvider.notifier)
        .refreshFromFirestore();
  } catch (e) {
    print('Auto-sync error: $e');
  }
}

/// Provider that gives the current sync service instance.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    hiveService: ref.watch(hiveServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});
