import '../models/runtime_actor.dart';

class ImageActor extends RuntimeActor {
  const ImageActor({
    required super.id,
    super.positionX,
    super.positionY,
    super.rotation,
    super.scale,
    super.opacity,
    super.visible,
    super.state,
  }) : super(type: 'image');

  factory ImageActor.fromJson(Map<String, dynamic> json) {
    final base = RuntimeActor.fromJson({...json, 'type': 'image'});
    return ImageActor(
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
