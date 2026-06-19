class SceneAnchor {
  final String id;
  final double x;
  final double y;
  final String label;

  const SceneAnchor({
    required this.id,
    required this.x,
    required this.y,
    required this.label,
  });
}

class SceneZone {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final String label;

  const SceneZone({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
  });
}

class SceneDefinition {
  final String id;
  final String background;
  final String primaryObject;
  final String primaryVariable;
  final String primaryOutcome;
  final List<String> backgroundLayers;
  final List<String> assetIds;
  final List<SceneAnchor> anchors;
  final List<SceneZone> zones;
  final List<String> overlays;

  const SceneDefinition({
    required this.id,
    required this.background,
    required this.primaryObject,
    required this.primaryVariable,
    required this.primaryOutcome,
    this.backgroundLayers = const [],
    this.assetIds = const [],
    this.anchors = const [],
    this.zones = const [],
    this.overlays = const [],
  });
}
