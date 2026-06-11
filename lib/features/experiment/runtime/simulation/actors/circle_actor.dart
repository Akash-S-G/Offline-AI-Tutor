import '../models/runtime_actor.dart';

class CircleActor extends RuntimeActor {
  const CircleActor({
    required super.id,
    super.positionX,
    super.positionY,
    super.rotation,
    super.scale,
    super.opacity,
    super.visible,
    super.state,
  }) : super(type: 'circle');

  factory CircleActor.fromJson(Map<String, dynamic> json) {
    final base = RuntimeActor.fromJson({...json, 'type': 'circle'});
    return CircleActor(
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
