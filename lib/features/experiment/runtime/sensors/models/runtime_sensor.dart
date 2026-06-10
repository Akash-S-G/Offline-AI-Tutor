import '../../models/runtime_variable.dart';
import 'runtime_sensor_state.dart';
import 'runtime_sensor_type.dart';

class RuntimeSensor {
  final String variableId;
  final String variableName;
  final RuntimeSensorType type;
  final Map<String, dynamic> config;
  final RuntimeSensorState state;

  const RuntimeSensor({
    required this.variableId,
    required this.variableName,
    required this.type,
    this.config = const {},
    required this.state,
  });

  factory RuntimeSensor.fromVariable(RuntimeVariable variable) {
    final type = runtimeSensorTypeFromVariableType(variable.type);
    if (type == null) {
      throw ArgumentError('Variable ${variable.id} is not a sensor variable.');
    }
    return RuntimeSensor(
      variableId: variable.id,
      variableName: variable.name,
      type: type,
      config: variable.metadata,
      state: RuntimeSensorState(type: type, registered: true),
    );
  }

  RuntimeSensor copyWith({RuntimeSensorState? state}) {
    return RuntimeSensor(
      variableId: variableId,
      variableName: variableName,
      type: type,
      config: config,
      state: state ?? this.state,
    );
  }
}
