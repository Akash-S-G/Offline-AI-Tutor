import '../runtime_event.dart';
import 'runtime_experiment_state.dart';

RuntimeEvent experimentStateEvent(
  String message,
  RuntimeExperimentState state, {
  Map<String, dynamic>? metadata,
}) {
  return RuntimeEvent(
    id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: _eventTypeFor(message),
    message: message,
    metadata: {
      'experimentId': state.experimentId,
      'status': state.status.name,
      'runtimeSeconds': state.runtime.inMilliseconds / 1000,
      ...?metadata,
    },
  );
}

RuntimeEventType _eventTypeFor(String message) {
  switch (message) {
    case 'ExperimentStarted':
      return RuntimeEventType.sessionStarted;
    case 'ExperimentPaused':
      return RuntimeEventType.sessionPaused;
    case 'ExperimentResumed':
      return RuntimeEventType.sessionResumed;
    case 'ExperimentCompleted':
      return RuntimeEventType.sessionCompleted;
    case 'ExperimentStopped':
      return RuntimeEventType.sessionStopped;
    default:
      return RuntimeEventType.custom;
  }
}
