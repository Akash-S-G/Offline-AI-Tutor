class SceneDefinitionV3 {
  final String sceneId;
  final List<String> backgroundAssets;
  final List<String> actorAssets;
  final List<String> effectAssets;
  final String theme;
  final Map<String, dynamic> defaultLayout;

  const SceneDefinitionV3({
    required this.sceneId,
    required this.backgroundAssets,
    required this.actorAssets,
    required this.effectAssets,
    required this.theme,
    this.defaultLayout = const {},
  });

  factory SceneDefinitionV3.fromJson(Map<String, dynamic> json) {
    return SceneDefinitionV3(
      sceneId: json['sceneId'] as String,
      backgroundAssets: (json['backgroundAssets'] as List?)?.cast<String>() ?? [],
      actorAssets: (json['actorAssets'] as List?)?.cast<String>() ?? [],
      effectAssets: (json['effectAssets'] as List?)?.cast<String>() ?? [],
      theme: json['theme'] as String? ?? 'default',
      defaultLayout: json['defaultLayout'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sceneId': sceneId,
      'backgroundAssets': backgroundAssets,
      'actorAssets': actorAssets,
      'effectAssets': effectAssets,
      'theme': theme,
      'defaultLayout': defaultLayout,
    };
  }
}
