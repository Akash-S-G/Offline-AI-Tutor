class BuilderScene {
  final String id;
  final String name;
  final String description;
  final List<String> tags;

  BuilderScene({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
  });

  BuilderScene copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? tags,
  }) {
    return BuilderScene(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sceneId': id,
      'name': name,
      'description': description,
      'tags': tags,
    };
  }
}
