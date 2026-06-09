class BuilderVariable {
  final String id;
  final String name;
  final String type;
  final dynamic defaultValue;
  final String description;
  final Map<String, dynamic> runtimeConfig;

  BuilderVariable({
    required this.id,
    required this.name,
    required this.type,
    this.defaultValue,
    required this.description,
    Map<String, dynamic>? runtimeConfig,
  }) : runtimeConfig = runtimeConfig ?? const {};

  factory BuilderVariable.fromJson(Map<String, dynamic> json) {
    final runtimeConfig = Map<String, dynamic>.from(
      json['runtimeConfig'] as Map? ?? const {},
    );
    if (runtimeConfig.isEmpty) {
      runtimeConfig.addAll(_extractRuntimeConfig(json));
    }
    return BuilderVariable(
      id: json['id']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'numberInput',
      defaultValue: json['value'],
      description: json['description']?.toString() ?? '',
      runtimeConfig: runtimeConfig,
    );
  }

  BuilderVariable copyWith({
    String? id,
    String? name,
    String? type,
    dynamic defaultValue,
    String? description,
    Map<String, dynamic>? runtimeConfig,
  }) {
    return BuilderVariable(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      description: description ?? this.description,
      runtimeConfig: runtimeConfig ?? this.runtimeConfig,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': defaultValue, // Matches PlaygroundVariable mapping expectation
      'description': description,
      'runtimeConfig': runtimeConfig,
      ...runtimeConfig,
      if (runtimeConfig['autoStart'] != null)
        'running': runtimeConfig['autoStart'],
      if (runtimeConfig['intervalSeconds'] != null)
        'interval': runtimeConfig['intervalSeconds'],
    };
  }

  static Map<String, dynamic> _extractRuntimeConfig(Map<String, dynamic> json) {
    dynamic read(String key) => json[key];
    switch (json['type']?.toString()) {
      case 'elapsedTime':
        return {
          if (read('startValue') != null) 'startValue': read('startValue'),
        };
      case 'countdown':
        return {
          if (read('startValue') != null) 'startValue': read('startValue'),
          if (read('autoStart') != null) 'autoStart': read('autoStart'),
        };
      case 'interval':
        return {
          if (read('intervalSeconds') != null)
            'intervalSeconds': read('intervalSeconds'),
          if (read('interval') != null) 'intervalSeconds': read('interval'),
        };
      case 'average':
      case 'minimum':
      case 'maximum':
        return {
          if (read('dependencies') != null)
            'dependencies': _stringList(read('dependencies')),
        };
      case 'distance':
        return {
          if (read('speedVariable') != null)
            'speedVariable': read('speedVariable'),
          if (read('timeVariable') != null)
            'timeVariable': read('timeVariable'),
        };
      case 'velocity':
        return {
          if (read('distanceVariable') != null)
            'distanceVariable': read('distanceVariable'),
          if (read('timeVariable') != null)
            'timeVariable': read('timeVariable'),
        };
      case 'acceleration':
        return {
          if (read('velocityVariable') != null)
            'velocityVariable': read('velocityVariable'),
          if (read('timeVariable') != null)
            'timeVariable': read('timeVariable'),
        };
      case 'force':
        return {
          if (read('massVariable') != null)
            'massVariable': read('massVariable'),
          if (read('accelerationVariable') != null)
            'accelerationVariable': read('accelerationVariable'),
        };
      case 'power':
        return {
          if (read('forceVariable') != null)
            'forceVariable': read('forceVariable'),
          if (read('velocityVariable') != null)
            'velocityVariable': read('velocityVariable'),
        };
      case 'energy':
        return {
          if (read('powerVariable') != null)
            'powerVariable': read('powerVariable'),
          if (read('timeVariable') != null)
            'timeVariable': read('timeVariable'),
        };
      default:
        return const {};
    }
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((entry) => entry.toString()).toList(growable: false);
    }
    if (value is String) {
      return value
          .split(',')
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}
