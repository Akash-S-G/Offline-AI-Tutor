import '../runtime_event.dart';

enum RuntimeSessionEventType {
  sessionSaved,
  sessionLoaded,
  sessionDeleted,
  autosaveCompleted,
  sessionRecoveryAvailable,
}

RuntimeEvent runtimeSessionEvent(
  RuntimeSessionEventType type, {
  required String sessionId,
  required String experimentId,
  Map<String, dynamic>? metadata,
}) {
  return RuntimeEvent(
    id: '${type.name}_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: RuntimeEventType.custom,
    message: switch (type) {
      RuntimeSessionEventType.sessionSaved => 'SessionSaved',
      RuntimeSessionEventType.sessionLoaded => 'SessionLoaded',
      RuntimeSessionEventType.sessionDeleted => 'SessionDeleted',
      RuntimeSessionEventType.autosaveCompleted => 'AutosaveCompleted',
      RuntimeSessionEventType.sessionRecoveryAvailable =>
        'SessionRecoveryAvailable',
    },
    metadata: {
      'sessionEventType': type.name,
      'sessionId': sessionId,
      'experimentId': experimentId,
      ...?metadata,
    },
  );
}
