// ignore_for_file: avoid_print

import 'dart:async';

import '../../domain/models/experiment_models.dart';
import '../../domain/enums/experiment_enums.dart';
import '../../platform/experiment_capability_provider_impl.dart';
import '../../platform/experiment_capability_cache.dart';
import 'experiment_execution_orchestrator.dart';

class ExperimentExecutionValidator {
  Future<void> validate() async {
    print('--------------------------------------------------');
    print('EXPERIMENT ORCHESTRATOR VALIDATION');
    print('--------------------------------------------------');

    final cache = ExperimentCapabilityCache();
    final provider = ExperimentCapabilityProviderImpl(cache);
    final orchestrator = ExperimentExecutionOrchestrator(provider);

    // 1. Create Mock Manifest
    final manifest = ExperimentManifest(
      id: 'demo_orchestrator_1',
      title: 'Pendulum Test',
      description: 'Orchestrator End-To-End Test',
      subject: 'Physics',
      grade: '10th',
      chapter: 'Mechanics',
      topic: 'Motion',
      difficulty: ExperimentDifficulty.easy,
      estimatedDurationMinutes: 5,
      requiredSensors: ['accelerometer'],
      supportedModes: [ExperimentExecutionMode.simulation, ExperimentExecutionMode.observation],
      steps: [],
      visualizations: [],
      supportsSimulation: true,
      supportsSensorExecution: true,
      supportsObservationMode: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 2. Setup Event Listener
    final subscription = orchestrator.eventStream.listen((event) {
      print('  -> Orchestrator Event: ${event.type.name} Payload: ${event.message}');
    });

    try {
      // 3. Prepare
      await orchestrator.prepare(manifest);
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Start
      await orchestrator.start();
      await Future.delayed(const Duration(milliseconds: 200));

      // 5. Pause
      await orchestrator.pause();
      await Future.delayed(const Duration(milliseconds: 100));

      // 6. Resume
      await orchestrator.resume();
      await Future.delayed(const Duration(milliseconds: 200));

      // 7. Stop
      await orchestrator.stop();
      await Future.delayed(const Duration(milliseconds: 100));

      // 8. Result
      final result = await orchestrator.getResult();
      if (result != null) {
        print('');
        print('=== EXECUTION RESULT ===');
        print('Success: ${result.success}');
        print('Mode: ${result.executionMode.name}');
        print('Duration: ${result.metrics.duration.inMilliseconds} ms');
        print('Events: ${result.metrics.eventCount}');
        print('Errors: ${result.metrics.errorCount}');
        print('========================');
      }

    } catch (e) {
      print('Validation failed: $e');
    } finally {
      // 9. Dispose
      await subscription.cancel();
      await orchestrator.dispose();
      print('--------------------------------------------------');
    }
  }
}
