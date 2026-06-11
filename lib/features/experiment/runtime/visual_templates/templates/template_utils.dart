import 'dart:math' as math;

import '../../simulation/models/runtime_actor.dart';
import '../models/runtime_visual_template_context.dart';

double readDouble(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

String readLabel(RuntimeVisualTemplateContext context) {
  return context.runtimeConfig['label']?.toString() ??
      context.objectState.state['label']?.toString() ??
      context.objectId
          .replaceAll(RegExp(r'^(obj_|var_)'), '')
          .replaceAll('_', ' ');
}

String? readVariableId(RuntimeVisualTemplateContext context) {
  return context.runtimeConfig['variableId']?.toString() ??
      context.runtimeConfig['linked_variable']?.toString() ??
      context.runtimeConfig['linkedVariable']?.toString() ??
      context.objectState.state['variableId']?.toString() ??
      context.objectState.state['linked_variable']?.toString();
}

double normalizedValue(RuntimeVisualTemplateContext context) {
  final value = readDouble(context.objectState.state['value'], 0);
  final min = readDouble(
    context.runtimeConfig['min'] ?? context.objectState.state['min'],
    0,
  );
  final max = readDouble(
    context.runtimeConfig['max'] ?? context.objectState.state['max'],
    100,
  );
  if (max <= min) return 0;
  return ((value - min) / (max - min)).clamp(0, 1).toDouble();
}

RuntimeActor actor({
  required String id,
  required String type,
  required double x,
  required double y,
  Map<String, dynamic> state = const {},
  double rotation = 0,
  double scale = 1,
  double opacity = 1,
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

double gaugeRotation(double normalized) {
  return -math.pi * 0.75 + normalized * math.pi * 1.5;
}
