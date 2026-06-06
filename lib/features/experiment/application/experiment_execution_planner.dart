// ignore_for_file: avoid_print

import '../domain/models/experiment_models.dart';
import '../runtime/playground/models/playground_scene.dart';
import 'experiment_capability_analyzer.dart';
import 'experiment_execution_plan.dart';

class ExperimentExecutionPlanner {
  ExperimentExecutionPlan buildPlan(
    ExperimentManifest experiment,
    ExperimentCapabilityReport report, [
    PlaygroundScene? scene,
  ]) {
    final warnings = <String>[];

    if (report.unsupportedRequirements.isNotEmpty) {
      warnings.add('Missing sensors: ${report.unsupportedRequirements.join(', ')}');
    }

    if (!report.fullyExecutable) {
      warnings.add('Experiment cannot be fully executed with current device capabilities.');
    }

    print('[EXPERIMENT] PLAN_CREATED for ${experiment.id} with mode ${report.recommendedMode.name}');

    return ExperimentExecutionPlan(
      experimentId: experiment.id,
      selectedMode: report.recommendedMode,
      requiredSensors: experiment.requiredSensors,
      missingSensors: report.unsupportedRequirements,
      executionSteps: experiment.steps,
      visualizations: experiment.visualizations,
      estimatedDuration: experiment.estimatedDurationMinutes,
      warnings: warnings,
      sceneDefinition: scene,
    );
  }
}
