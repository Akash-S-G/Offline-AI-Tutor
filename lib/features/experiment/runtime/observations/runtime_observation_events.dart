import '../runtime_event.dart';
import 'runtime_observation.dart';

RuntimeEvent observationRecordedEvent(RuntimeObservation observation) {
  return RuntimeEvent(
    id: 'ObservationRecorded_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: RuntimeEventType.custom,
    message: 'ObservationRecorded',
    metadata: {
      'observationId': observation.id,
      'runtimeSeconds': observation.runtimeSeconds,
      'source': observation.source,
      'valueCount': observation.values.length,
    },
  );
}

RuntimeEvent observationRemovedEvent(RuntimeObservation observation) {
  return RuntimeEvent(
    id: 'ObservationRemoved_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: RuntimeEventType.custom,
    message: 'ObservationRemoved',
    metadata: {
      'observationId': observation.id,
      'runtimeSeconds': observation.runtimeSeconds,
      'source': observation.source,
    },
  );
}

RuntimeEvent observationsClearedEvent({required int count}) {
  return RuntimeEvent(
    id: 'ObservationsCleared_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: RuntimeEventType.custom,
    message: 'ObservationsCleared',
    metadata: {'count': count},
  );
}

RuntimeEvent observationExportedEvent({required int rowCount}) {
  return RuntimeEvent(
    id: 'ObservationExported_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: RuntimeEventType.custom,
    message: 'ObservationExported',
    metadata: {'rowCount': rowCount},
  );
}
