class RuntimeVisualBinding {
  final String id;
  final String variableId;
  final String actorId;
  final String property;
  final bool active;
  final Map<String, dynamic> transform;

  const RuntimeVisualBinding({
    required this.id,
    required this.variableId,
    required this.actorId,
    required this.property,
    this.active = true,
    this.transform = const {},
  });

  factory RuntimeVisualBinding.fromJson(Map<String, dynamic> json) {
    final variableId =
        json['variableId']?.toString() ??
        json['variable']?.toString() ??
        json['sourceVariable']?.toString() ??
        '';
    final actorId =
        json['actorId']?.toString() ?? json['objectId']?.toString() ?? '';
    final property = json['property']?.toString() ?? 'value';
    return RuntimeVisualBinding(
      id: json['id']?.toString() ?? '${variableId}_${actorId}_$property',
      variableId: variableId,
      actorId: actorId,
      property: property,
      active: json['active'] is bool ? json['active'] as bool : true,
      transform: Map<String, dynamic>.from(
        json['transform'] as Map? ??
            {
              if (json['min'] != null) 'min': json['min'],
              if (json['max'] != null) 'max': json['max'],
              if (json['outputMin'] != null) 'outputMin': json['outputMin'],
              if (json['outputMax'] != null) 'outputMax': json['outputMax'],
            },
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variableId': variableId,
      'actorId': actorId,
      'property': property,
      'active': active,
      if (transform.isNotEmpty) 'transform': transform,
    };
  }

  static const supportedProperties = {
    'positionX',
    'positionY',
    'rotation',
    'scale',
    'opacity',
    'width',
    'height',
    'color',
    'text',
  };

  bool get supported => supportedProperties.contains(property);
}
