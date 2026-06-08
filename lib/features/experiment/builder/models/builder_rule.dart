class BuilderRule {
  final String id;
  final String name;
  final Map<String, dynamic> condition;
  final Map<String, dynamic> action;
  final String description;

  BuilderRule({
    required this.id,
    required this.name,
    required this.condition,
    required this.action,
    required this.description,
  });

  BuilderRule copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? condition,
    Map<String, dynamic>? action,
    String? description,
  }) {
    return BuilderRule(
      id: id ?? this.id,
      name: name ?? this.name,
      condition: condition ?? this.condition,
      action: action ?? this.action,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ruleId': id,
      'name': name,
      'trigger': 'any', // Default generic trigger
      'condition': condition,
      'action': action,
      'description': description,
    };
  }
}
