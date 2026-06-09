import '../runtime_event.dart';
import 'runtime_measurement.dart';

RuntimeEvent measurementCollectedEvent(RuntimeMeasurement measurement) {
  return RuntimeEvent(
    id: 'MeasurementCollected_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: RuntimeEventType.custom,
    message: 'MeasurementCollected',
    metadata: {
      'variableId': measurement.variableId,
      'variableName': measurement.variableName,
      'value': measurement.value,
      'runtimeSeconds': measurement.runtimeSeconds,
      'source': measurement.source,
    },
  );
}

RuntimeEvent measurementDiscardedEvent(RuntimeMeasurement measurement) {
  return RuntimeEvent(
    id: 'MeasurementDiscarded_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: RuntimeEventType.custom,
    message: 'MeasurementDiscarded',
    metadata: {
      'variableId': measurement.variableId,
      'variableName': measurement.variableName,
      'value': measurement.value,
      'runtimeSeconds': measurement.runtimeSeconds,
      'source': measurement.source,
    },
  );
}

RuntimeEvent measurementsClearedEvent({
  String? variableId,
  required int count,
}) {
  return RuntimeEvent(
    id: 'MeasurementsCleared_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: RuntimeEventType.custom,
    message: 'MeasurementsCleared',
    metadata: {'variableId': variableId, 'count': count},
  );
}
