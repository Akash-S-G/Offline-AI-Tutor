class RuntimeObservation {
  final String id;
  final double runtimeSeconds;
  final DateTime timestamp;
  final Map<String, dynamic> values;
  final String source;

  const RuntimeObservation({
    required this.id,
    required this.runtimeSeconds,
    required this.timestamp,
    required this.values,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'runtimeSeconds': runtimeSeconds,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'values': values,
    };
  }
}

enum ObservationCollectionMode { manual, interval }
