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

  factory RuntimeObservation.fromJson(Map<String, dynamic> json) {
    return RuntimeObservation(
      id: json['id']?.toString() ?? '',
      runtimeSeconds: json['runtimeSeconds'] is num
          ? (json['runtimeSeconds'] as num).toDouble()
          : double.tryParse(json['runtimeSeconds']?.toString() ?? '') ?? 0,
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      values: Map<String, dynamic>.from(json['values'] as Map? ?? const {}),
      source: json['source']?.toString() ?? 'manual',
    );
  }

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
