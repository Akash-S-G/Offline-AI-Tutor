import '../../runtime/simulation/animations/runtime_animation.dart';
import '../../runtime/simulation/bindings/runtime_visual_binding.dart';
import '../../runtime/simulation/models/runtime_actor.dart';
import 'visual_preset_context.dart';

typedef PresetActorFactory =
    List<RuntimeActor> Function(VisualPresetContext context);
typedef PresetBindingFactory =
    List<RuntimeVisualBinding> Function(VisualPresetContext context);
typedef PresetAnimationFactory =
    List<RuntimeAnimation> Function(VisualPresetContext context);

class VisualPreset {
  final String id;
  final String name;
  final String description;
  final List<String> supportedVariables;
  final List<String> supportedObjects;
  final PresetActorFactory actorFactory;
  final PresetBindingFactory bindingFactory;
  final PresetAnimationFactory animationFactory;

  const VisualPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.supportedVariables,
    required this.supportedObjects,
    required this.actorFactory,
    required this.bindingFactory,
    required this.animationFactory,
  });
}
