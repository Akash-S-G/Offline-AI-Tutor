class BuilderRule {
  final String id;
  final String name;
  final String type;
  final String trigger;
  final Map<String, dynamic> condition;
  final List<Map<String, dynamic>> actions;
  final Map<String, dynamic> runtimeConfig;
  final String description;

  BuilderRule({
    required this.id,
    required this.name,
    this.type = 'runtime',
    this.trigger = 'variableChanged',
    required this.condition,
    List<Map<String, dynamic>>? actions,
    Map<String, dynamic>? action,
    this.description = '',
    Map<String, dynamic>? runtimeConfig,
  }) : actions =
           actions ??
           (runtimeConfig?['actions'] is List
               ? _actionsFrom(runtimeConfig?['actions'])
               : [if (action != null && action.isNotEmpty) action]),
       runtimeConfig = {
         ...?runtimeConfig,
         'trigger': trigger,
         'condition': condition,
         'actions':
             actions ??
             (runtimeConfig?['actions'] is List
                 ? _actionsFrom(runtimeConfig?['actions'])
                 : [if (action != null && action.isNotEmpty) action]),
       };

  factory BuilderRule.fromJson(Map<String, dynamic> json) {
    final condition = Map<String, dynamic>.from(
      json['condition'] as Map? ??
          (json['runtimeConfig'] is Map
              ? (json['runtimeConfig'] as Map)['condition'] as Map? ?? const {}
              : const {}),
    );
    final action = Map<String, dynamic>.from(
      json['action'] as Map? ?? const {},
    );
    final runtimeConfig = Map<String, dynamic>.from(
      json['runtimeConfig'] as Map? ?? const {},
    );
    final actions = json['actions'] is List
        ? _actionsFrom(json['actions'])
        : runtimeConfig['actions'] is List
        ? _actionsFrom(runtimeConfig['actions'])
        : <Map<String, dynamic>>[if (action.isNotEmpty) action];
    final trigger =
        json['trigger']?.toString() ??
        runtimeConfig['trigger']?.toString() ??
        'variableChanged';
    return BuilderRule(
      id: json['ruleId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type:
          json['type']?.toString() ??
          runtimeConfig['type']?.toString() ??
          'runtime',
      trigger: trigger,
      condition: condition,
      actions: actions,
      description: json['description']?.toString() ?? '',
      runtimeConfig: runtimeConfig,
    );
  }

  BuilderRule copyWith({
    String? id,
    String? name,
    String? type,
    String? trigger,
    Map<String, dynamic>? condition,
    List<Map<String, dynamic>>? actions,
    Map<String, dynamic>? action,
    String? description,
    Map<String, dynamic>? runtimeConfig,
  }) {
    return BuilderRule(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      trigger: trigger ?? this.trigger,
      condition: condition ?? this.condition,
      actions: actions ?? (action == null ? this.actions : [action]),
      description: description ?? this.description,
      runtimeConfig: runtimeConfig ?? this.runtimeConfig,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ruleId': id,
      'name': name,
      'type': type,
      'trigger': trigger,
      'condition': condition,
      'action': action,
      'actions': actions,
      'description': description,
      'runtimeConfig': {
        ...runtimeConfig,
        'type': type,
        'trigger': trigger,
        'condition': condition,
        'actions': actions,
      },
    };
  }

  Map<String, dynamic> get action =>
      actions.isEmpty ? const {} : Map<String, dynamic>.from(actions.first);

  static List<Map<String, dynamic>> _actionsFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }
}
