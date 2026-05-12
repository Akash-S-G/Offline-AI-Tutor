import 'dart:async';

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
    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      versions.record(task.manifest);
      yield 'synced:${task.manifest.packId}@${task.manifest.version}';
    }
  }
}
