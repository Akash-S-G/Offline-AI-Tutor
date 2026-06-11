import 'dart:math' as math;

import '../../simulation/animations/runtime_animation.dart';
import '../../simulation/bindings/runtime_visual_binding.dart';
import '../../simulation/models/runtime_actor.dart';
import '../models/runtime_visual_template_context.dart';
import 'runtime_visual_template.dart';
import 'template_utils.dart';

class GaugeVisualTemplate extends RuntimeVisualTemplate {
  @override
  String get name => 'GaugeVisualTemplate';

  @override
  List<RuntimeActor> buildActors(RuntimeVisualTemplateContext context) {
    final label = readLabel(context);
    final value = readDouble(context.objectState.state['value'], 0);
    final normalized = normalizedValue(context);
    return [
      actor(
        id: '${context.objectId}_gauge_circle',
        type: 'circle',
        x: context.originX,
        y: context.originY,
        state: {'radius': 46, 'color': '#e0f2fe'},
      ),
      actor(
        id: '${context.objectId}_needle',
        type: 'arrow',
        x: context.originX,
        y: context.originY,
        rotation: gaugeRotation(normalized),
        state: {'width': 42, 'strokeWidth': 4, 'color': '#dc2626'},
      ),
      actor(
        id: '${context.objectId}_label',
        type: 'text',
        x: context.originX,
        y: context.originY - 64,
        state: {'text': label, 'fontSize': 13, 'color': '#334155'},
      ),
      actor(
        id: '${context.objectId}_value',
        type: 'text',
        x: context.originX,
        y: context.originY + 62,
        state: {
          'text': value.toStringAsFixed(0),
          'fontSize': 18,
          'color': '#0f172a',
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
        id: '${context.objectId}_needle_rotation_binding',
        variableId: variableId,
        actorId: '${context.objectId}_needle',
        property: 'rotation',
        transform: {
          'min': min,
          'max': max,
          'outputMin': -math.pi * 0.75,
          'outputMax': math.pi * 0.75,
        },
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
        id: '${context.objectId}_needle_smooth',
        actorId: '${context.objectId}_needle',
        type: 'oscillate',
        duration: 1,
        enabled: false,
      ),
    ];
  }
}
