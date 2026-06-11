import '../../simulation/animations/runtime_animation.dart';
import '../../simulation/bindings/runtime_visual_binding.dart';
import '../../simulation/models/runtime_actor.dart';
import '../models/runtime_visual_template_context.dart';
import 'runtime_visual_template.dart';
import 'template_utils.dart';

class NumericDisplayVisualTemplate extends RuntimeVisualTemplate {
  @override
  String get name => 'NumericDisplayVisualTemplate';

  @override
  List<RuntimeActor> buildActors(RuntimeVisualTemplateContext context) {
    final label = readLabel(context);
    final value = context.objectState.state['value'] ?? 0;
    final unit =
        context.runtimeConfig['unit']?.toString() ??
        context.objectState.state['unit']?.toString() ??
        '';
    return [
      actor(
        id: '${context.objectId}_label',
        type: 'text',
        x: context.originX,
        y: context.originY - 22,
        state: {'text': label, 'fontSize': 14, 'color': '#334155'},
      ),
      actor(
        id: '${context.objectId}_value',
        type: 'text',
        x: context.originX,
        y: context.originY + 4,
        state: {'text': '$value', 'fontSize': 24, 'color': '#0f172a'},
      ),
      actor(
        id: '${context.objectId}_unit',
        type: 'text',
        x: context.originX,
        y: context.originY + 30,
        state: {'text': unit, 'fontSize': 13, 'color': '#64748b'},
      ),
    ];
  }

  @override
  List<RuntimeVisualBinding> buildBindings(
    RuntimeVisualTemplateContext context,
  ) {
    final variableId = readVariableId(context);
    if (variableId == null || variableId.isEmpty) return const [];
    return [
      RuntimeVisualBinding(
        id: '${context.objectId}_value_text_binding',
        variableId: variableId,
        actorId: '${context.objectId}_value',
        property: 'text',
      ),
    ];
  }

  @override
  List<RuntimeAnimation> buildAnimations(RuntimeVisualTemplateContext context) {
    return const [];
  }
}
