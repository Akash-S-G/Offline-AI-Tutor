import '../models/runtime_object_state.dart';
import '../objects/behavior/runtime_object_behavior.dart';
import '../variable_store.dart';
import 'bar_chart_state.dart';
import 'runtime_multi_binding.dart';
import 'scientific_value_reader.dart';

class BarChartBehavior extends PlaceholderRuntimeObjectBehavior {
  final VariableStore? variables;
  final Map<String, dynamic>? objectJson;

  BarChartBehavior({this.variables, this.objectJson});

  BarChartState buildState() {
    final object = objectJson ?? const <String, dynamic>{};
    final properties = objectProperties(object);
    final binding = RuntimeMultiBinding.fromObjectJson(object);
    final variableIds = binding.variablesForPrefix('bar_');
    final bars = properties['bars'];
    final labels = <String>[];
    final values = <double>[];

    if (bars is List && bars.isNotEmpty) {
      for (final bar in bars) {
        if (bar is Map) {
          final label =
              bar['label']?.toString() ??
              bar['variableId']?.toString() ??
              'Bar ${labels.length + 1}';
          final variableId = bar['variableId']?.toString();
          labels.add(label);
          values.add(
            numericValue(
              variableId == null
                  ? bar['value']
                  : variables?.getValue(variableId),
            ),
          );
        }
      }
    } else {
      for (var i = 0; i < variableIds.length; i++) {
        final variableId = variableIds[i];
        final variable = variables?.getVariable(variableId);
        labels.add(variable?.name ?? variableId);
        values.add(numericValue(variable?.value));
      }
    }

    if (values.isEmpty) return const BarChartState.empty();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    return BarChartState(
      labels: labels,
      values: values,
      min: min,
      max: max,
      updatedAt: DateTime.now(),
    );
  }

  @override
  ValidationResult validateState(RuntimeObjectState state) {
    return const ValidationResult.valid();
  }
}
