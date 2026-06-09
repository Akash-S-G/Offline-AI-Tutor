enum BindingDirection { variableToObject, objectToVariable, bidirectional }

class RuntimeBinding {
  final String bindingId;
  final String variableId;
  final String objectId;
  final String objectProperty;
  final BindingDirection direction;
  final bool active;
  final DateTime createdAt;

  const RuntimeBinding({
    required this.bindingId,
    required this.variableId,
    required this.objectId,
    required this.objectProperty,
    this.direction = BindingDirection.variableToObject,
    required this.active,
    required this.createdAt,
  });

  bool get allowsVariableToObject =>
      direction == BindingDirection.variableToObject ||
      direction == BindingDirection.bidirectional;

  bool get allowsObjectToVariable =>
      direction == BindingDirection.objectToVariable ||
      direction == BindingDirection.bidirectional;

  RuntimeBinding copyWith({
    String? bindingId,
    String? variableId,
    String? objectId,
    String? objectProperty,
    BindingDirection? direction,
    bool? active,
    DateTime? createdAt,
  }) {
    return RuntimeBinding(
      bindingId: bindingId ?? this.bindingId,
      variableId: variableId ?? this.variableId,
      objectId: objectId ?? this.objectId,
      objectProperty: objectProperty ?? this.objectProperty,
      direction: direction ?? this.direction,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bindingId': bindingId,
      'variableId': variableId,
      'objectId': objectId,
      'objectProperty': objectProperty,
      'direction': direction.name,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
