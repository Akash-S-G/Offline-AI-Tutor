import '../models/runtime_object_state.dart';
import '../models/runtime_variable.dart';
import 'runtime_experiment_state.dart';

class RuntimeExperimentSnapshot {
  final Map<String, RuntimeVariable> variables;
  final List<RuntimeObjectState> objectStates;
  final int measurementsCount;
  final int observationsCount;
  final RuntimeExperimentState state;

  const RuntimeExperimentSnapshot({
    required this.variables,
    required this.objectStates,
    required this.measurementsCount,
    required this.observationsCount,
    required this.state,
  });

  Map<String, dynamic> toJson() {
    return {
      'variables': variables.map(
        (id, variable) => MapEntry(id, variable.toJson()),
      ),
      'objectStates': objectStates
          .map((objectState) => objectState.toJson())
          .toList(growable: false),
      'measurementsCount': measurementsCount,
      'observationsCount': observationsCount,
      'status': state.status.name,
      'state': state.toJson(),
    };
  }
}
