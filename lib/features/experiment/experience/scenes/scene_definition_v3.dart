class SceneDefinitionV3 {
  final String sceneId;
  final List<String> backgroundAssets;
  final List<String> actorAssets;
  final List<String> effectAssets;
  final String theme;
  final Map<String, dynamic> defaultLayout;

  /// Behaviors declared in the blueprint JSON, e.g. [{"type":"oscillation"}]
  final List<dynamic> behaviors;

  /// Effects declared in the blueprint JSON, e.g. [{"type":"motion_trail"}]
  final List<dynamic> effects;

  const SceneDefinitionV3({
    required this.sceneId,
    required this.backgroundAssets,
    required this.actorAssets,
    required this.effectAssets,
    required this.theme,
    this.defaultLayout = const {},
    this.behaviors = const [],
    this.effects = const [],
  });

  factory SceneDefinitionV3.fromJson(Map<String, dynamic> json) {
    return SceneDefinitionV3(
      sceneId: json['sceneId'] as String,
      backgroundAssets: (json['backgroundAssets'] as List?)?.cast<String>() ?? [],
      actorAssets: (json['actorAssets'] as List?)?.cast<String>() ?? [],
      effectAssets: (json['effectAssets'] as List?)?.cast<String>() ?? [],
      theme: json['theme'] as String? ?? 'default',
      defaultLayout: json['defaultLayout'] as Map<String, dynamic>? ?? {},
      behaviors: (json['behaviors'] as List?) ?? [],
      effects: (json['effects'] as List?) ?? [],
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
