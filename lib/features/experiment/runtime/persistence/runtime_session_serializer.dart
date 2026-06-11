import '../experiment_state/runtime_experiment_metrics.dart';
import '../experiment_state/runtime_experiment_status.dart';
import '../measurements/runtime_measurement.dart';
import '../models/runtime_object_state.dart';
import '../models/runtime_variable.dart';
import '../observations/runtime_observation.dart';
import 'runtime_session.dart';

class RuntimeSessionSerializer {
  const RuntimeSessionSerializer();

  Map<String, dynamic> toJson(RuntimeSession session) {
    return {
      'sessionId': session.sessionId,
      'experimentId': session.experimentId,
      'createdAt': session.createdAt.toIso8601String(),
      'updatedAt': session.updatedAt.toIso8601String(),
      'status': session.status.name,
      'variables': session.variables,
      'objectStates': session.objectStates,
      'metrics': session.metrics.toJson(),
      'observations': session.observations
          .map((observation) => observation.toJson())
          .toList(growable: false),
      'measurementCounts': session.measurementCounts,
      'measurements': session.measurements.map(
        (variableId, measurements) => MapEntry(
          variableId,
          measurements
              .map((measurement) => measurement.toJson())
              .toList(growable: false),
        ),
      ),
      'runtimeSeconds': session.runtimeSeconds,
      'autosaveCount': session.autosaveCount,
    };
  }

  RuntimeSession fromJson(Map<String, dynamic> json) {
    final measurementsJson = Map<String, dynamic>.from(
      json['measurements'] as Map? ?? const {},
    );
    final measurements = measurementsJson.map((variableId, entries) {
      final list = entries is List ? entries : const [];
      return MapEntry(
        variableId,
        list
            .whereType<Map>()
            .map((entry) {
              return RuntimeMeasurement.fromJson(
                Map<String, dynamic>.from(entry),
              );
            })
            .toList(growable: false),
      );
    });
    final measurementCounts =
        Map<String, dynamic>.from(
          json['measurementCounts'] as Map? ?? const {},
        ).map((key, value) {
          if (value is num) return MapEntry(key, value.toInt());
          return MapEntry(key, int.tryParse(value?.toString() ?? '') ?? 0);
        });

    return RuntimeSession(
      sessionId: json['sessionId']?.toString() ?? '',
      experimentId: json['experimentId']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      status: runtimeExperimentStatusFromName(json['status']?.toString()),
      variables: Map<String, dynamic>.from(
        json['variables'] as Map? ?? const {},
      ),
      objectStates: Map<String, dynamic>.from(
        json['objectStates'] as Map? ?? const {},
      ),
      metrics: json['metrics'] is Map
          ? RuntimeExperimentMetrics.fromJson(
              Map<String, dynamic>.from(json['metrics'] as Map),
            )
          : const RuntimeExperimentMetrics.empty(),
      observations: (json['observations'] as List? ?? const [])
          .whereType<Map>()
          .map((entry) {
            return RuntimeObservation.fromJson(
              Map<String, dynamic>.from(entry),
            );
          })
          .toList(growable: false),
      measurementCounts: measurementCounts,
      measurements: measurements,
      runtimeSeconds: json['runtimeSeconds'] is num
          ? (json['runtimeSeconds'] as num).toDouble()
          : double.tryParse(json['runtimeSeconds']?.toString() ?? '') ?? 0,
      autosaveCount: json['autosaveCount'] is num
          ? (json['autosaveCount'] as num).toInt()
          : int.tryParse(json['autosaveCount']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, RuntimeVariable> variablesFromSession(RuntimeSession session) {
    return session.variables.map((id, value) {
      return MapEntry(
        id,
        RuntimeVariable.fromJson(Map<String, dynamic>.from(value as Map)),
      );
    });
  }

  List<RuntimeObjectState> objectStatesFromSession(RuntimeSession session) {
    return session.objectStates.values
        .whereType<Map>()
        .map((value) {
          return RuntimeObjectState.fromObjectJson(
            Map<String, dynamic>.from(value),
          );
        })
        .toList(growable: false);
  }
}
