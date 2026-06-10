import '../runtime_event.dart';
import 'models/runtime_sensor_type.dart';

RuntimeEvent sensorVariableRegisteredEvent({
  required String variableId,
  required String variableName,
  required RuntimeSensorType sensorType,
}) {
  return _sensorEvent('SensorVariableRegistered', {
    'variableId': variableId,
    'variableName': variableName,
    'sensorType': sensorType.name,
  });
}

RuntimeEvent sensorStartedEvent(RuntimeSensorType sensorType) {
  return _sensorEvent('SensorStarted', {'sensorType': sensorType.name});
}

RuntimeEvent sensorStoppedEvent(RuntimeSensorType sensorType) {
  return _sensorEvent('SensorStopped', {'sensorType': sensorType.name});
}

RuntimeEvent sensorMeasurementReceivedEvent({
  required RuntimeSensorType sensorType,
  required String variableId,
  required Map<String, dynamic> values,
  Map<String, dynamic>? metadata,
}) {
  return _sensorEvent('SensorMeasurementReceived', {
    'sensorType': sensorType.name,
    'variableId': variableId,
    'values': values,
    ...?metadata,
  });
}

RuntimeEvent sensorPermissionDeniedEvent({
  required RuntimeSensorType sensorType,
  required String reason,
}) {
  return _sensorEvent('SensorPermissionDenied', {
    'sensorType': sensorType.name,
    'reason': reason,
  }, type: RuntimeEventType.error);
}

RuntimeEvent sensorErrorEvent({
  required RuntimeSensorType sensorType,
  required String message,
}) {
  return _sensorEvent('SensorError', {
    'sensorType': sensorType.name,
    'message': message,
  }, type: RuntimeEventType.error);
}

RuntimeEvent _sensorEvent(
  String message,
  Map<String, dynamic> metadata, {
  RuntimeEventType type = RuntimeEventType.custom,
}) {
  return RuntimeEvent(
    id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: type,
    message: message,
    metadata: metadata,
  );
}
