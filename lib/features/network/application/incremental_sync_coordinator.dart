import 'dart:async';

import '../../../config/app_environment.dart';
import 'pack_version_manager.dart';

class IncrementalSyncTask {
  const IncrementalSyncTask({required this.manifest, required this.payload});
  final PackManifest manifest;
  final Map<String, dynamic> payload;
}

class IncrementalSyncCoordinator {
  IncrementalSyncCoordinator({required this.versions});

  final PackVersionManager versions;
  final List<IncrementalSyncTask> _queue = [];

  void enqueue(IncrementalSyncTask task) {
    _queue.add(task);
  }

  Stream<String> process() async* {
    AppEnvironment.log(
      'SYNC',
      'Processing ${_queue.length} sync tasks',
    );
    
    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      versions.record(task.manifest);
      
      AppEnvironment.log(
        'SYNC',
        'Synced pack: ${task.manifest.packId}@${task.manifest.version}',
      );
      
      yield 'synced:${task.manifest.packId}@${task.manifest.version}';
    }
    
    AppEnvironment.log(
      'SYNC',
      'Sync processing completed',
    );
  }
}
