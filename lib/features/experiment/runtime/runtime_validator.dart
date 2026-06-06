// ignore_for_file: avoid_print

import '../domain/enums/experiment_enums.dart';
import '../application/experiment_execution_plan.dart';
import 'runtime_factory.dart';
import 'runtime_event.dart';

class RuntimeValidator {
  Future<void> validate() async {
    print('--------------------------------------------------');
    print('EXPERIMENT RUNTIME VALIDATION');
    print('--------------------------------------------------');

    final modes = [
      ExperimentExecutionMode.sensor,
      ExperimentExecutionMode.simulation,
      ExperimentExecutionMode.hybrid,
      ExperimentExecutionMode.observation,
    ];

    for (final mode in modes) {
      print('');
      print('=== Validating Mode: ${mode.name.toUpperCase()} ===');
      
      final plan = ExperimentExecutionPlan(
        experimentId: 'fake-experiment-id',
        selectedMode: mode,
        requiredSensors: [],
        missingSensors: [],
        executionSteps: [],
        visualizations: [],
        estimatedDuration: 10,
        warnings: [],
      );

      final runtime = RuntimeFactory.createRuntime(plan);

      // Listen to events to verify stream
      runtime.eventStream.listen((event) {
        print('  -> Stream received event: ${event.type.name} - ${event.message}');
      });

      await runtime.initialize();
      await Future.delayed(const Duration(milliseconds: 10));
      
      await runtime.start();
      await Future.delayed(const Duration(milliseconds: 10));
      
      runtime.emitEvent(RuntimeEventType.measurementReceived, 'Fake measurement data');
      
      await runtime.pause();
      await Future.delayed(const Duration(milliseconds: 10));
      
      await runtime.resume();
      await Future.delayed(const Duration(milliseconds: 10));
      
      await runtime.stop();
      await Future.delayed(const Duration(milliseconds: 10));
      
      await runtime.dispose();
      print('================================================');
    }
  }
}
