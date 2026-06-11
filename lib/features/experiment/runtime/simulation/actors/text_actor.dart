import '../models/runtime_actor.dart';

class TextActor extends RuntimeActor {
  const TextActor({
    required super.id,
    super.positionX,
    super.positionY,
    super.rotation,
    super.scale,
    super.opacity,
    super.visible,
    super.state,
  }) : super(type: 'text');

  factory TextActor.fromJson(Map<String, dynamic> json) {
    final base = RuntimeActor.fromJson({...json, 'type': 'text'});
    return TextActor(
      id: base.id,
      positionX: base.positionX,
      positionY: base.positionY,
      rotation: base.rotation,
      scale: base.scale,
      opacity: base.opacity,
      visible: base.visible,
      state: base.state,
    );
  }
}
