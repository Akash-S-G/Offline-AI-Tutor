import 'runtime_experiment_metrics.dart';
import 'runtime_experiment_status.dart';

class RuntimeExperimentState {
  final String experimentId;
  final RuntimeExperimentStatus status;
  final Duration runtime;
  final int observations;
  final int measurements;
  final int warnings;
  final int rulesTriggered;
  final DateTime startedAt;
  final DateTime? completedAt;
  final RuntimeExperimentMetrics metrics;

  const RuntimeExperimentState({
    required this.experimentId,
    required this.status,
    required this.runtime,
    required this.observations,
    required this.measurements,
    required this.warnings,
    required this.rulesTriggered,
    required this.startedAt,
    required this.completedAt,
    required this.metrics,
  });

  factory RuntimeExperimentState.created(String experimentId) {
    return RuntimeExperimentState(
      experimentId: experimentId,
      status: RuntimeExperimentStatus.created,
      runtime: Duration.zero,
      observations: 0,
      measurements: 0,
      warnings: 0,
      rulesTriggered: 0,
      startedAt: DateTime.now(),
      completedAt: null,
      metrics: const RuntimeExperimentMetrics.empty(),
    );
  }

  factory RuntimeExperimentState.fromJson(Map<String, dynamic> json) {
    final runtimeSeconds = json['runtimeSeconds'];
    final startedAt = DateTime.tryParse(json['startedAt']?.toString() ?? '');
    final completedAt = DateTime.tryParse(
      json['completedAt']?.toString() ?? '',
    );
    int readInt(String key) {
      final value = json[key];
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return RuntimeExperimentState(
      experimentId: json['experimentId']?.toString() ?? 'experiment',
      status: runtimeExperimentStatusFromName(json['status']?.toString()),
      runtime: Duration(
        milliseconds: runtimeSeconds is num
            ? (runtimeSeconds.toDouble() * 1000).round()
            : 0,
      ),
      observations: readInt('observations'),
      measurements: readInt('measurements'),
      warnings: readInt('warnings'),
      rulesTriggered: readInt('rulesTriggered'),
      startedAt: startedAt ?? DateTime.now(),
      completedAt: completedAt,
      metrics: json['metrics'] is Map
          ? RuntimeExperimentMetrics.fromJson(
              Map<String, dynamic>.from(json['metrics'] as Map),
            )
          : const RuntimeExperimentMetrics.empty(),
    );
  }

  RuntimeExperimentState copyWith({
    String? experimentId,
    RuntimeExperimentStatus? status,
    Duration? runtime,
    int? observations,
    int? measurements,
    int? warnings,
    int? rulesTriggered,
    DateTime? startedAt,
    Object? completedAt = _unset,
    RuntimeExperimentMetrics? metrics,
  }) {
    return RuntimeExperimentState(
      experimentId: experimentId ?? this.experimentId,
      status: status ?? this.status,
      runtime: runtime ?? this.runtime,
      observations: observations ?? this.observations,
      measurements: measurements ?? this.measurements,
      warnings: warnings ?? this.warnings,
      rulesTriggered: rulesTriggered ?? this.rulesTriggered,
      startedAt: startedAt ?? this.startedAt,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
      metrics: metrics ?? this.metrics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'experimentId': experimentId,
      'status': status.name,
      'runtimeSeconds': runtime.inMilliseconds / 1000,
      'observations': observations,
      'measurements': measurements,
      'warnings': warnings,
      'rulesTriggered': rulesTriggered,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metrics': metrics.toJson(),
    };
  }

  static const Object _unset = Object();
}
