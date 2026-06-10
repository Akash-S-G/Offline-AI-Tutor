import 'dart:math' as math;

import '../models/runtime_object_state.dart';
import '../objects/behavior/runtime_object_behavior.dart';
import '../variable_store.dart';
import 'runtime_multi_binding.dart';
import 'scientific_value_reader.dart';
import 'vector_visualizer_state.dart';

class VectorVisualizerBehavior extends PlaceholderRuntimeObjectBehavior {
  final VariableStore? variables;
  final Map<String, dynamic>? objectJson;

  VectorVisualizerBehavior({this.variables, this.objectJson});

  VectorVisualizerState buildState() {
    final object = objectJson ?? const <String, dynamic>{};
    final properties = objectProperties(object);
    final binding = RuntimeMultiBinding.fromObjectJson(object);
    final unit = properties['unit']?.toString() ?? '';

    final sourceId = binding.variableForRole('value');
    final sourceValue = sourceId == null ? null : variables?.getValue(sourceId);
    var x = 0.0;
    var y = 0.0;
    var z = 0.0;
    if (sourceValue is Map) {
      x = numericValue(sourceValue, field: 'x');
      y = numericValue(sourceValue, field: 'y');
      z = numericValue(sourceValue, field: 'z');
    } else {
      final xId = binding.variableForRole('x');
      final yId = binding.variableForRole('y');
      final zId = binding.variableForRole('z');
      x = numericValue(
        xId == null ? properties['x'] : variables?.getValue(xId),
      );
      y = numericValue(
        yId == null ? properties['y'] : variables?.getValue(yId),
      );
      z = numericValue(
        zId == null ? properties['z'] : variables?.getValue(zId),
      );
    }

    final magnitude = math.sqrt(x * x + y * y + z * z);
    final direction = math.atan2(y, x) * 180 / math.pi;
    return VectorVisualizerState(
      x: x,
      y: y,
      z: z,
      magnitude: magnitude,
      direction: direction,
      unit: unit,
      updatedAt: DateTime.now(),
    );
  }

  @override
  ValidationResult validateState(RuntimeObjectState state) {
    return const ValidationResult.valid();
  }
}
