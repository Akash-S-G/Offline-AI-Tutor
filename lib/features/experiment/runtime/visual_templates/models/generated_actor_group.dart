class GeneratedActorGroup {
  final String objectId;
  final String templateName;
  final List<String> actorIds;
  final List<String> bindingIds;
  final List<String> animationIds;

  const GeneratedActorGroup({
    required this.objectId,
    required this.templateName,
    this.actorIds = const [],
    this.bindingIds = const [],
    this.animationIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'templateName': templateName,
      'actorIds': actorIds,
      'bindingIds': bindingIds,
      'animationIds': animationIds,
    };
  }
}
