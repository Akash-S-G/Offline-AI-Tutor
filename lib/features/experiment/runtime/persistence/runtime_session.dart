import '../experiment_state/runtime_experiment_metrics.dart';
import '../experiment_state/runtime_experiment_status.dart';
import '../measurements/runtime_measurement.dart';
import '../observations/runtime_observation.dart';

class RuntimeSession {
  final String sessionId;
  final String experimentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RuntimeExperimentStatus status;
  final Map<String, dynamic> variables;
  final Map<String, dynamic> objectStates;
  final RuntimeExperimentMetrics metrics;
  final List<RuntimeObservation> observations;
  final Map<String, int> measurementCounts;
  final Map<String, List<RuntimeMeasurement>> measurements;
  final double runtimeSeconds;
  final int autosaveCount;

  const RuntimeSession({
    required this.sessionId,
    required this.experimentId,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.variables,
    required this.objectStates,
    required this.metrics,
    required this.observations,
    required this.measurementCounts,
    required this.measurements,
    required this.runtimeSeconds,
    this.autosaveCount = 0,
  });

  RuntimeSession copyWith({
    String? sessionId,
    String? experimentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    RuntimeExperimentStatus? status,
    Map<String, dynamic>? variables,
    Map<String, dynamic>? objectStates,
    RuntimeExperimentMetrics? metrics,
    List<RuntimeObservation>? observations,
    Map<String, int>? measurementCounts,
    Map<String, List<RuntimeMeasurement>>? measurements,
    double? runtimeSeconds,
    int? autosaveCount,
  }) {
    return RuntimeSession(
      sessionId: sessionId ?? this.sessionId,
      experimentId: experimentId ?? this.experimentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      variables: variables ?? this.variables,
      objectStates: objectStates ?? this.objectStates,
      metrics: metrics ?? this.metrics,
      observations: observations ?? this.observations,
      measurementCounts: measurementCounts ?? this.measurementCounts,
      measurements: measurements ?? this.measurements,
      runtimeSeconds: runtimeSeconds ?? this.runtimeSeconds,
      autosaveCount: autosaveCount ?? this.autosaveCount,
    );
  }
}
