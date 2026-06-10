import 'dart:math';

import '../variable_store.dart';
import 'runtime_rule_condition.dart';

class RuntimeConditionEvaluator {
  final VariableStore variables;

  RuntimeConditionEvaluator({required this.variables});

  bool evaluate(RuntimeRuleCondition condition) {
    if (condition.operator == 'always') return true;
    final variableId = condition.variableId;
    if (variableId == null) return false;
    final actual = _valueForCondition(
      variables.getValue(variableId),
      condition.field,
    );
    final expected = condition.value;

    switch (condition.operator) {
      case '==':
        return actual == expected;
      case '!=':
        return actual != expected;
      case '>':
        return actual is num && expected is num && actual > expected;
      case '>=':
        return actual is num && expected is num && actual >= expected;
      case '<':
        return actual is num && expected is num && actual < expected;
      case '<=':
        return actual is num && expected is num && actual <= expected;
      default:
        return false;
    }
  }

  dynamic _valueForCondition(dynamic value, String? field) {
    if (value is Map) {
      if (field != null && field.isNotEmpty && value.containsKey(field)) {
        return value[field];
      }
      final numericValues = [
        'magnitude',
        'value',
        'amplitude',
        'lux',
        'distance',
      ].map((key) => value[key]).whereType<num>().toList(growable: false);
      if (numericValues.isNotEmpty) return numericValues.first;
      final x = value['x'];
      final y = value['y'];
      final z = value['z'];
      if (x is num && y is num && z is num) {
        return sqrt(x * x + y * y + z * z);
      }
    }
    return value;
  }
}
