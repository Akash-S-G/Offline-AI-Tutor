class BuilderRule {
  final String id;
  final String name;
  final Map<String, dynamic> condition;
  final Map<String, dynamic> action;
  final String description;
  final Map<String, dynamic> runtimeConfig;

  BuilderRule({
    required this.id,
    required this.name,
    required this.condition,
    required this.action,
    required this.description,
    Map<String, dynamic>? runtimeConfig,
  }) : runtimeConfig = runtimeConfig ?? const {};

  factory BuilderRule.fromJson(Map<String, dynamic> json) {
    final condition = Map<String, dynamic>.from(
      json['condition'] as Map? ?? const {},
    );
    final action = Map<String, dynamic>.from(
      json['action'] as Map? ?? const {},
    );
    final actions = json['actions'] is List
        ? List<Map<String, dynamic>>.from(
            (json['actions'] as List).map(
              (entry) => Map<String, dynamic>.from(entry as Map),
            ),
          )
        : <Map<String, dynamic>>[if (action.isNotEmpty) action];
    final runtimeConfig = Map<String, dynamic>.from(
      json['runtimeConfig'] as Map? ??
          {'condition': condition, 'actions': actions},
    );
    return BuilderRule(
      id: json['ruleId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      condition: condition,
      action: action,
      description: json['description']?.toString() ?? '',
      runtimeConfig: runtimeConfig,
    );
  }

  BuilderRule copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? condition,
    Map<String, dynamic>? action,
    String? description,
    Map<String, dynamic>? runtimeConfig,
  }) {
    return BuilderRule(
      id: id ?? this.id,
      name: name ?? this.name,
      condition: condition ?? this.condition,
      action: action ?? this.action,
      description: description ?? this.description,
      runtimeConfig: runtimeConfig ?? this.runtimeConfig,
    );
  }

  Map<String, dynamic> toJson() {
    final actions = _actions;
    return {
      'ruleId': id,
      'name': name,
      'trigger': 'any', // Default generic trigger
      'condition': condition,
      'action': actions.isNotEmpty ? actions.first : action,
      'actions': actions,
      'description': description,
      'runtimeConfig': {
        ...runtimeConfig,
        'condition': condition,
        'actions': actions,
      },
    };
  }

  List<Map<String, dynamic>> get _actions {
    final rawActions = runtimeConfig['actions'];
    if (rawActions is List) {
      return rawActions
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList(growable: false);
    }
    return action.isEmpty ? const [] : [action];
  }
}
