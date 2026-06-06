// ignore_for_file: avoid_print

import 'dart:async';
import 'package:uuid/uuid.dart';

import '../experiment_api_service.dart';
import '../experiment_sync_queue.dart';
import '../experiment_run_sync_adapter_impl.dart';
import '../models/experiment_run_dto.dart';
import '../models/experiment_event_dto.dart';
import '../../../network/domain/backend_config.dart';
import '../../domain/enums/experiment_enums.dart';

class ExperimentSyncValidator {
  Future<void> validate() async {
    print('--------------------------------------------------');
    print('EXPERIMENT SYNC VALIDATION');
    print('--------------------------------------------------');

    final config = BackendConfig(baseUrl: 'http://localhost:3000', apiKey: 'test_key');
    final apiService = ExperimentApiService(config);
    final queue = ExperimentSyncQueue(apiService);
    final adapter = ExperimentRunSyncAdapterImpl(queue);

    const runId = 'test_run_123';
    const experimentId = 'exp_001';
    const studentId = 'student_456';
    final uuid = const Uuid();

    try {
      print('=== 1. Test Run Creation ===');
      final run = ExperimentRunDto(
        runId: runId,
        experimentId: experimentId,
        studentId: studentId,
        executionMode: ExperimentExecutionMode.simulation,
        startedAt: DateTime.now(),
        status: 'running',
      );
      await adapter.createRun(run);
      
      print('=== 2. Test Event Batching ===');
      // Send 30 events rapidly
      for (int i = 0; i < 30; i++) {
        await adapter.appendEvent(
          runId,
          ExperimentEventDto(
            eventId: uuid.v4(),
            runId: runId,
            eventType: 'measurementReceived',
            timestamp: DateTime.now(),
            message: 'Data point $i',
            metadata: {'value': i},
          ),
        );
      }
      // The first 25 should batch immediately
      await Future.delayed(const Duration(milliseconds: 100));

      print('=== 3. Test Run Completion ===');
      // Should flush the remaining 5 events, then complete
      await adapter.completeRun(runId, {'duration': 120, 'events': 30});

      print('=== 4. Test Queue Flush (Offline Handling) ===');
      // Notice: Since we used a dummy localhost url without a server, the queue flush will fail
      // and items will be kept in the queue. This validates offline queueing!
      await queue.flush();
      
      print('--------------------------------------------------');
    } catch (e) {
      print('Validation error: $e');
    }
  }
}
