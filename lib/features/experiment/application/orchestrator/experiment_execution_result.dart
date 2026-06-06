import '../../domain/enums/experiment_enums.dart';
import '../../runtime/runtime_metrics.dart';

class ExperimentExecutionResult {
  final String experimentId;
  final String runId;
  final ExperimentExecutionMode executionMode;
  final DateTime startedAt;
  final DateTime completedAt;
  final RuntimeMetrics metrics;
  final bool success;
  final String? errorMessage;

  ExperimentExecutionResult({
    required this.experimentId,
    required this.runId,
    required this.executionMode,
    required this.startedAt,
    required this.completedAt,
    required this.metrics,
    required this.success,
    this.errorMessage,
  });
}
