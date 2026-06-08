class BuilderObject {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> properties;

  BuilderObject({
    required this.id,
    required this.name,
    required this.type,
    required this.properties,
  });

  BuilderObject copyWith({
    String? id,
    String? name,
    String? type,
    Map<String, dynamic>? properties,
  }) {
    return BuilderObject(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      properties: properties ?? this.properties,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': id,
      'objectType': type,
      'name': name,
      'properties': properties,
      'state': {},
    };
  }
}
