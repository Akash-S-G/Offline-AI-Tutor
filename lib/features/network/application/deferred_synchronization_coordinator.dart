import 'persistent_sync_recovery_manager.dart';

class DeferredSynchronizationCoordinator {
  DeferredSynchronizationCoordinator({required this.recovery});

  final PersistentSyncRecoveryManager recovery;

  void defer(Map<String, dynamic> operation) => recovery.recordFailure(operation);

  List<Map<String, dynamic>> flush() => recovery.drainFailures();
}
