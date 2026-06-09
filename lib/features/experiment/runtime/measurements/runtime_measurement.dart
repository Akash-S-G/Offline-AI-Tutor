class RuntimeMeasurement {
  final String variableId;
  final String variableName;
  final dynamic value;
  final DateTime timestamp;
  final double runtimeSeconds;
  final String source;

  const RuntimeMeasurement({
    required this.variableId,
    required this.variableName,
    required this.value,
    required this.timestamp,
    required this.runtimeSeconds,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'variableId': variableId,
      'variableName': variableName,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'runtimeSeconds': runtimeSeconds,
      'source': source,
    };
  }
}
