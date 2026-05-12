import 'deferred_sync_manager.dart';
import 'offline_state_persistence.dart';

class OfflineRecoveryCoordinator {
  OfflineRecoveryCoordinator({required this.persistence, required this.deferredSync});

  final OfflineStatePersistence persistence;
  final DeferredSyncManager deferredSync;

  void markOffline(String reason) {
    persistence.save('offline_reason', reason);
  }

  List<dynamic> recoverDeferred() {
    return deferredSync.drain();
  }
}
