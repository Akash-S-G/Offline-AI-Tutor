import '../../simulation/animations/runtime_animation.dart';
import '../../simulation/bindings/runtime_visual_binding.dart';
import '../../simulation/models/runtime_actor.dart';
import '../models/runtime_visual_template_context.dart';

abstract class RuntimeVisualTemplate {
  String get name;

  List<RuntimeActor> buildActors(RuntimeVisualTemplateContext context);

  List<RuntimeVisualBinding> buildBindings(
    RuntimeVisualTemplateContext context,
  );

  List<RuntimeAnimation> buildAnimations(RuntimeVisualTemplateContext context);
}
