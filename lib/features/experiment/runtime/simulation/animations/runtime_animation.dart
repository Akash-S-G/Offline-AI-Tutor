class RuntimeAnimation {
  final String id;
  final String actorId;
  final String type;
  final double duration;
  final bool repeat;
  final bool enabled;
  final Map<String, dynamic> state;

  const RuntimeAnimation({
    required this.id,
    required this.actorId,
    required this.type,
    this.duration = 1,
    this.repeat = true,
    this.enabled = true,
    this.state = const {},
  });

  factory RuntimeAnimation.fromJson(Map<String, dynamic> json) {
    final actorId = json['actorId']?.toString() ?? '';
    final type = json['type']?.toString() ?? 'rotate';
    return RuntimeAnimation(
      id: json['id']?.toString() ?? '${actorId}_$type',
      actorId: actorId,
      type: type,
      duration: _double(json['duration'], fallback: 1),
      repeat: json['repeat'] is bool ? json['repeat'] as bool : true,
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
      state:
          json['state'] is Map
                ? Map<String, dynamic>.from(json['state'] as Map)
                : Map<String, dynamic>.from(json)
            ..removeWhere((key, _) => _reserved.contains(key)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actorId': actorId,
      'type': type,
      'duration': duration,
      'repeat': repeat,
      'enabled': enabled,
      'state': state,
    };
  }

  static const supportedTypes = {
    'move',
    'rotate',
    'scale',
    'fade',
    'pulse',
    'oscillate',
    'orbit',
  };

  bool get supported => supportedTypes.contains(type);

  static const _reserved = {
    'id',
    'actorId',
    'type',
    'duration',
    'repeat',
    'enabled',
    'state',
  };

  static double _double(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
