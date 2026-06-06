enum PlaygroundEventType {
  sceneLoaded,
  objectCreated,
  objectUpdated,
  variableChanged,
  ruleExecuted,
  interaction,
  custom,
}

class PlaygroundEvent {
  final String eventId;
  final PlaygroundEventType eventType;
  final DateTime timestamp;
  final Map<String, dynamic>? payload;

  PlaygroundEvent({
    required this.eventId,
    required this.eventType,
    required this.timestamp,
    this.payload,
  });
}
