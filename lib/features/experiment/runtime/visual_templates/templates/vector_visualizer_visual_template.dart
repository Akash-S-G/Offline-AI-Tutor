import 'dart:math' as math;

import '../../simulation/animations/runtime_animation.dart';
import '../../simulation/bindings/runtime_visual_binding.dart';
import '../../simulation/models/runtime_actor.dart';
import '../models/runtime_visual_template_context.dart';
import 'runtime_visual_template.dart';
import 'template_utils.dart';

class VectorVisualizerVisualTemplate extends RuntimeVisualTemplate {
  @override
  String get name => 'VectorVisualizerVisualTemplate';

  @override
  List<RuntimeActor> buildActors(RuntimeVisualTemplateContext context) {
    final value = context.objectState.state['value'];
    final vector = value is Map ? value : const {};
    final x = readDouble(
      vector['x'],
      readDouble(context.objectState.state['x'], 1),
    );
    final y = readDouble(
      vector['y'],
      readDouble(context.objectState.state['y'], 0),
    );
    final magnitude = math.sqrt(x * x + y * y);
    return [
      actor(
        id: '${context.objectId}_arrow',
        type: 'arrow',
        x: context.originX,
        y: context.originY,
        rotation: math.atan2(y, x),
        state: {
          'width': 30 + magnitude * 8,
          'strokeWidth': 4,
          'color': '#7c3aed',
        },
      ),
      actor(
        id: '${context.objectId}_magnitude',
        type: 'text',
        x: context.originX,
        y: context.originY + 38,
        state: {'text': magnitude.toStringAsFixed(2), 'fontSize': 13},
      ),
      actor(
        id: '${context.objectId}_direction',
        type: 'text',
        x: context.originX,
        y: context.originY + 58,
        state: {
          'text': '${math.atan2(y, x).toStringAsFixed(2)} rad',
          'fontSize': 12,
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
    return [
      RuntimeVisualBinding(
        id: '${context.objectId}_arrow_length_binding',
        variableId: variableId,
        actorId: '${context.objectId}_arrow',
        property: 'width',
        transform: {
          'field': 'magnitude',
          'min': 0,
          'max': 10,
          'outputMin': 20,
          'outputMax': 120,
        },
      ),
      RuntimeVisualBinding(
        id: '${context.objectId}_arrow_rotation_binding',
        variableId: variableId,
        actorId: '${context.objectId}_arrow',
        property: 'rotation',
        transform: {
          'field': 'direction',
          'min': -math.pi,
          'max': math.pi,
          'outputMin': -math.pi,
          'outputMax': math.pi,
        },
      ),
    ];
  }

  @override
  List<RuntimeAnimation> buildAnimations(RuntimeVisualTemplateContext context) {
    return const [];
  }
}
