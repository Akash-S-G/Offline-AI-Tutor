import '../../runtime/simulation/animations/runtime_animation.dart';
import '../../runtime/simulation/bindings/runtime_visual_binding.dart';
import '../../runtime/simulation/models/runtime_actor.dart';

class VisualPresetScene {
  final String presetId;
  final List<RuntimeActor> actors;
  final List<RuntimeVisualBinding> bindings;
  final List<RuntimeAnimation> animations;

  const VisualPresetScene({
    required this.presetId,
    this.actors = const [],
    this.bindings = const [],
    this.animations = const [],
  });
}
