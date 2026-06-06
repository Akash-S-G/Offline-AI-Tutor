import '../../domain/enums/experiment_enums.dart';

class ExperimentRunDto {
  final String runId;
  final String experimentId;
  final String studentId;
  final ExperimentExecutionMode executionMode;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status;
  final Map<String, dynamic>? metrics;

  ExperimentRunDto({
    required this.runId,
    required this.experimentId,
    required this.studentId,
    required this.executionMode,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'run_id': runId,
      'experiment_id': experimentId,
      'student_id': studentId,
      'execution_mode': executionMode.name,
      'started_at': startedAt.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'status': status,
      if (metrics != null) 'metrics': metrics,
    };
  }

  factory ExperimentRunDto.fromJson(Map<String, dynamic> json) {
    return ExperimentRunDto(
      runId: json['run_id'],
      experimentId: json['experiment_id'],
      studentId: json['student_id'],
      executionMode: ExperimentExecutionMode.values.firstWhere(
        (e) => e.name == json['execution_mode'],
        orElse: () => ExperimentExecutionMode.observation,
      ),
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      status: json['status'],
      metrics: json['metrics'],
    );
  }
}
