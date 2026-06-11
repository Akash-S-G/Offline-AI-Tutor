import '../models/runtime_actor.dart';

class ParticleActor extends RuntimeActor {
  const ParticleActor({
    required super.id,
    super.positionX,
    super.positionY,
    super.rotation,
    super.scale,
    super.opacity,
    super.visible,
    super.state,
  }) : super(type: 'particle');

  factory ParticleActor.fromJson(Map<String, dynamic> json) {
    final base = RuntimeActor.fromJson({...json, 'type': 'particle'});
    return ParticleActor(
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
