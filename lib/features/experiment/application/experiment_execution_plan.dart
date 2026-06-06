import '../domain/enums/experiment_enums.dart';
import '../domain/models/experiment_models.dart';

class ExperimentExecutionPlan {
  final String experimentId;
  final ExperimentExecutionMode selectedMode;
  final List<String> requiredSensors;
  final List<String> missingSensors;
  final List<ExperimentStep> executionSteps;
  final List<ExperimentVisualization> visualizations;
  final int estimatedDuration;
  final List<String> warnings;

  ExperimentExecutionPlan({
    required this.experimentId,
    required this.selectedMode,
    required this.requiredSensors,
    required this.missingSensors,
    required this.executionSteps,
    required this.visualizations,
    required this.estimatedDuration,
    required this.warnings,
  });
}
