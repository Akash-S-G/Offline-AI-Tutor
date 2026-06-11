import '../../simulation/animations/runtime_animation.dart';
import '../../simulation/bindings/runtime_visual_binding.dart';
import '../../simulation/models/runtime_actor.dart';
import '../models/runtime_visual_template_context.dart';
import 'runtime_visual_template.dart';
import 'template_utils.dart';

class ProgressBarVisualTemplate extends RuntimeVisualTemplate {
  @override
  String get name => 'ProgressBarVisualTemplate';

  @override
  List<RuntimeActor> buildActors(RuntimeVisualTemplateContext context) {
    final label = readLabel(context);
    final width = 150.0;
    final fillWidth = width * normalizedValue(context);
    return [
      actor(
        id: '${context.objectId}_label',
        type: 'text',
        x: context.originX,
        y: context.originY - 24,
        state: {'text': label, 'fontSize': 13, 'color': '#334155'},
      ),
      actor(
        id: '${context.objectId}_bar_background',
        type: 'rectangle',
        x: context.originX,
        y: context.originY,
        state: {'width': width, 'height': 18, 'color': '#e5e7eb'},
      ),
      actor(
        id: '${context.objectId}_bar_fill',
        type: 'rectangle',
        x: context.originX - (width - fillWidth) / 2,
        y: context.originY,
        state: {'width': fillWidth, 'height': 18, 'color': '#0f766e'},
      ),
      actor(
        id: '${context.objectId}_value',
        type: 'text',
        x: context.originX,
        y: context.originY + 28,
        state: {
          'text': '${(normalizedValue(context) * 100).toStringAsFixed(0)}%',
          'fontSize': 13,
        },
      ),
    ];
  }

  @override
  List<RuntimeVisualBinding> buildBindings(
    RuntimeVisualTemplateContext context,
  ) {
    final variableId = readVariableId(context);
    if (variableId == null || variableId.isEmpty) return const [];
    final min = readDouble(
      context.runtimeConfig['min'] ?? context.objectState.state['min'],
      0,
    );
    final max = readDouble(
      context.runtimeConfig['max'] ?? context.objectState.state['max'],
      100,
    );
    return [
      RuntimeVisualBinding(
        id: '${context.objectId}_fill_width_binding',
        variableId: variableId,
        actorId: '${context.objectId}_bar_fill',
        property: 'width',
        transform: {'min': min, 'max': max, 'outputMin': 0, 'outputMax': 150},
      ),
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
    return [
      RuntimeAnimation(
        id: '${context.objectId}_fill_smooth',
        actorId: '${context.objectId}_bar_fill',
        type: 'scale',
        duration: 0.2,
        enabled: false,
      ),
    ];
  }
}
