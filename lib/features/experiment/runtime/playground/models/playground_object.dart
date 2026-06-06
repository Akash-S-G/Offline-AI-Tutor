class PlaygroundObject {
  final String objectId;
  final String objectType;
  final String name;
  final Map<String, dynamic> properties;
  Map<String, dynamic> state;
  final Map<String, dynamic>? metadata;

  PlaygroundObject({
    required this.objectId,
    required this.objectType,
    required this.name,
    required this.properties,
    required this.state,
    this.metadata,
  });
}
