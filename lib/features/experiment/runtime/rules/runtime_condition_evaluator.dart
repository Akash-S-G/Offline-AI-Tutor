import '../variable_store.dart';
import 'runtime_rule_condition.dart';

class RuntimeConditionEvaluator {
  final VariableStore variables;

  RuntimeConditionEvaluator({required this.variables});

  bool evaluate(RuntimeRuleCondition condition) {
    if (condition.operator == 'always') return true;
    final variableId = condition.variableId;
    if (variableId == null) return false;
    final actual = variables.getValue(variableId);
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
}
