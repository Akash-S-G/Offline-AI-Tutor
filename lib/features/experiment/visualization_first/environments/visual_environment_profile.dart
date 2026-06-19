class VisualEnvironmentProfile {
  final String id;
  final String name;
  final String description;
  final String backgroundMode;
  final List<String> ambientMotions;
  final Map<String, dynamic> palette;

  const VisualEnvironmentProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundMode,
    this.ambientMotions = const [],
    this.palette = const {},
  });

  bool get isLightweight {
    return backgroundMode != '3d' && !ambientMotions.contains('heavyShader');
  }
}
