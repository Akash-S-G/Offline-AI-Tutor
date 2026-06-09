import 'object_registry.dart';
import 'runtime_event_bus.dart';
import 'rules/runtime_action_dispatcher.dart';
import 'rules/runtime_condition_evaluator.dart';
import 'rules/runtime_rule_engine.dart';
import 'rules/runtime_rule_registry.dart';
import 'variable_store.dart';

class RuleEngine {
  final RuntimeRuleRegistry _registry = RuntimeRuleRegistry();
  late final RuntimeRuleEngine _engine;

  RuleEngine(
    VariableStore variableStore,
    RuntimeEventBus eventBus,
    ObjectRegistry objectRegistry,
  ) {
    _engine = RuntimeRuleEngine(
      registry: _registry,
      conditionEvaluator: RuntimeConditionEvaluator(variables: variableStore),
      actionDispatcher: RuntimeActionDispatcher(
        variables: variableStore,
        objects: objectRegistry,
        eventBus: eventBus,
      ),
      eventBus: eventBus,
    );
  }

  void initialize(List<Map<String, dynamic>> rulesJson) {
    _engine.initialize(rulesJson);
  }

  List<Map<String, dynamic>> get allRules => _engine.allRules;

  List<RuntimeRuleState> get ruleStates => _engine.ruleStates;

  void evaluateContinuousRules(double dt) {
    _engine.evaluateContinuousRules(dt);
  }

  void dispose() {
    _engine.dispose();
  }
}
