import '../models/runtime_actor.dart';

class ArrowActor extends RuntimeActor {
  const ArrowActor({
    required super.id,
    super.positionX,
    super.positionY,
    super.rotation,
    super.scale,
    super.opacity,
    super.visible,
    super.state,
  }) : super(type: 'arrow');

  factory ArrowActor.fromJson(Map<String, dynamic> json) {
    final base = RuntimeActor.fromJson({...json, 'type': 'arrow'});
    return ArrowActor(
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
