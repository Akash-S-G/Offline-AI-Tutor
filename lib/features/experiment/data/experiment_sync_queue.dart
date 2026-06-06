// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:collection';
import 'pending_experiment_sync.dart';
import 'experiment_api_service.dart';

class ExperimentSyncQueue {
  final Queue<PendingExperimentSync> _queue = Queue<PendingExperimentSync>();
  final ExperimentApiService _apiService;
  bool _isFlushing = false;

  ExperimentSyncQueue(this._apiService);

  void enqueue(PendingExperimentSync syncOp) {
    _queue.add(syncOp);
    print('[EXPERIMENT_SYNC] QUEUED_OFFLINE id=${syncOp.id} type=${syncOp.operationType.name}');
    _attemptFlush();
  }

  PendingExperimentSync? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeFirst();
  }

  void retry(PendingExperimentSync syncOp) {
    syncOp.retryCount++;
    _queue.addFirst(syncOp);
  }

  Future<void> flush() async {
    await _attemptFlush();
  }

  Future<void> _attemptFlush() async {
    if (_isFlushing || _queue.isEmpty) return;
    _isFlushing = true;
    print('[EXPERIMENT_SYNC] FLUSH_START items=${_queue.length}');

    try {
      while (_queue.isNotEmpty) {
        final current = dequeue()!;
        try {
          switch (current.operationType) {
            case SyncOperationType.createRun:
              await _apiService.createRun(current.runDto!);
              break;
            case SyncOperationType.appendEvents:
              await _apiService.appendEvents(current.runId!, current.events!);
              break;
            case SyncOperationType.completeRun:
              await _apiService.completeRun(current.runId!, current.runDto!.metrics!);
              break;
          }
          print('[EXPERIMENT_SYNC] FLUSH_SUCCESS id=${current.id}');
        } catch (e) {
          print('[EXPERIMENT_SYNC] FLUSH_FAILED id=${current.id} retryCount=${current.retryCount} error=$e');
          if (current.retryCount < 3) {
            retry(current);
          } else {
            print('[EXPERIMENT_SYNC] MAX_RETRIES_REACHED dropping id=${current.id}');
          }
          // Stop flushing on first failure to maintain order and wait for network
          break;
        }
      }
    } finally {
      _isFlushing = false;
    }
  }
}
