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

  factory RuntimeMeasurement.fromJson(Map<String, dynamic> json) {
    return RuntimeMeasurement(
      variableId: json['variableId']?.toString() ?? '',
      variableName: json['variableName']?.toString() ?? '',
      value: json['value'],
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      runtimeSeconds: json['runtimeSeconds'] is num
          ? (json['runtimeSeconds'] as num).toDouble()
          : double.tryParse(json['runtimeSeconds']?.toString() ?? '') ?? 0,
      source: json['source']?.toString() ?? 'runtime',
    );
  }

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
