class BuilderVariable {
  final String id;
  final String name;
  final String type;
  final dynamic defaultValue;
  final String description;

  BuilderVariable({
    required this.id,
    required this.name,
    required this.type,
    this.defaultValue,
    required this.description,
  });

  BuilderVariable copyWith({
    String? id,
    String? name,
    String? type,
    dynamic defaultValue,
    String? description,
  }) {
    return BuilderVariable(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': defaultValue, // Matches PlaygroundVariable mapping expectation
      'description': description,
    };
  }
}
