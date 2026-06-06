enum RuntimeEventType {
  sessionCreated,
  sessionStarted,
  sessionPaused,
  sessionResumed,
  sessionStopped,
  sessionCompleted,
  measurementReceived,
  warning,
  error,
  custom,
}

class RuntimeEvent {
  final String id;
  final DateTime timestamp;
  final RuntimeEventType type;
  final String message;
  final Map<String, dynamic>? metadata;

  RuntimeEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.message,
    this.metadata,
  });
}
