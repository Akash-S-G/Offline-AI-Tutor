import '../../runtime/simulation/animations/runtime_animation.dart';
import '../../runtime/simulation/bindings/runtime_visual_binding.dart';
import '../../runtime/simulation/models/runtime_actor.dart';
import '../models/visual_preset.dart';
import '../models/visual_preset_context.dart';

RuntimeActor presetActor({
  required String id,
  required String type,
  required double x,
  required double y,
  double rotation = 0,
  double scale = 1,
  double opacity = 1,
  Map<String, dynamic> state = const {},
}) {
  return RuntimeActor(
    id: id,
    type: type,
    positionX: x,
    positionY: y,
    rotation: rotation,
    scale: scale,
    opacity: opacity,
    state: state,
  );
}

RuntimeVisualBinding binding({
  required String id,
  required String variableId,
  required String actorId,
  required String property,
  Map<String, dynamic> transform = const {},
}) {
  return RuntimeVisualBinding(
    id: id,
    variableId: variableId,
    actorId: actorId,
    property: property,
    transform: transform,
  );
}

RuntimeAnimation animation({
  required String id,
  required String actorId,
  required String type,
  double duration = 1,
  bool repeat = true,
  bool enabled = true,
  Map<String, dynamic> state = const {},
}) {
  return RuntimeAnimation(
    id: id,
    actorId: actorId,
    type: type,
    duration: duration,
    repeat: repeat,
    enabled: enabled,
    state: state,
  );
}

VisualPreset simplePreset({
  required String id,
  required String name,
  required String description,
  required List<String> supportedVariables,
  required PresetActorFactory actors,
  required PresetBindingFactory bindings,
  PresetAnimationFactory? animations,
}) {
  return VisualPreset(
    id: id,
    name: name,
    description: description,
    supportedVariables: supportedVariables,
    supportedObjects: const [],
    actorFactory: actors,
    bindingFactory: bindings,
    animationFactory: animations ?? (VisualPresetContext context) => const [],
  );
}
