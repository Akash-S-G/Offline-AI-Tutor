import 'dart:async';

import '../runtime_event.dart';
import '../runtime_event_bus.dart';
import '../runtime_variable_events.dart';
import 'runtime_action_dispatcher.dart';
import 'runtime_condition_evaluator.dart';
import 'runtime_rule.dart';
import 'runtime_rule_registry.dart';

class RuntimeRuleEngine {
  final RuntimeRuleRegistry registry;
  final RuntimeConditionEvaluator conditionEvaluator;
  final RuntimeActionDispatcher actionDispatcher;
  final RuntimeEventBus eventBus;

  StreamSubscription<RuntimeEvent>? _subscription;

  RuntimeRuleEngine({
    required this.registry,
    required this.conditionEvaluator,
    required this.actionDispatcher,
    required this.eventBus,
  });

  void initialize(List<Map<String, dynamic>> rulesJson) {
    registry.clear();
    for (final json in rulesJson) {
      final rule = RuntimeRule.fromJson(json);
      if (rule.ruleId.isEmpty) continue;
      registry.registerRule(rule);
      _emit('RuleRegistered', rule);
      registry.activateRule(rule.ruleId);
      _emit('RuleActivated', rule);
    }
    _subscription?.cancel();
    _subscription = eventBus.stream.listen(_handleEvent);
  }

  List<Map<String, dynamic>> get allRules =>
      registry.rules.map((rule) => rule.toJson()).toList(growable: false);

  List<RuntimeRuleState> get ruleStates => registry.states;

  void evaluateContinuousRules(double dt) {
    for (final state in registry.states) {
      if (!state.active) continue;
      if (state.rule.trigger == RuntimeRuleTrigger.continuous ||
          state.rule.trigger == RuntimeRuleTrigger.always) {
        _evaluate(state.rule, triggerSource: 'continuous');
      }
    }
  }

  void _handleEvent(RuntimeEvent event) {
    if (event.message == 'VariableUpdated' &&
        event.metadata?['variableEventType'] ==
            RuntimeVariableEventType.variableUpdated.name) {
      _evaluateVariableChanged(event.metadata?['variableId']?.toString());
    } else if (event.metadata?['interactionType'] != null) {
      _evaluateObjectInteraction(event.metadata?['objectId']?.toString());
    }
  }

  void _evaluateVariableChanged(String? variableId) {
    if (variableId == null) return;
    for (final state in registry.states) {
      if (!state.active) continue;
      final rule = state.rule;
      if (rule.trigger != RuntimeRuleTrigger.variableChanged) continue;
      if (rule.condition.variableId != variableId) continue;
      _evaluate(rule, triggerSource: 'variableChanged');
    }
  }

  void _evaluateObjectInteraction(String? objectId) {
    for (final state in registry.states) {
      if (!state.active) continue;
      final rule = state.rule;
      if (rule.trigger != RuntimeRuleTrigger.objectInteraction) continue;
      _evaluate(rule, triggerSource: objectId ?? 'objectInteraction');
    }
  }

  void _evaluate(RuntimeRule rule, {required String triggerSource}) {
    final passed = conditionEvaluator.evaluate(rule.condition);
    registry.recordEvaluation(rule.ruleId, passed);
    _emit('RuleEvaluated', rule, {'result': passed, 'trigger': triggerSource});
    _emit(passed ? 'RulePassed' : 'RuleFailed', rule, {'result': passed});
    if (!passed) return;

    final actionExecuted = actionDispatcher.dispatch(rule);
    _emit('RuleFired', rule, {
      'result': passed,
      'actionType': rule.action.type,
      'actionTypes': rule.actions.map((action) => action.type).toList(),
      'actionExecuted': actionExecuted,
    });
  }

  void _emit(
    String message,
    RuntimeRule rule, [
    Map<String, dynamic>? metadata,
  ]) {
    eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: {
          'ruleId': rule.ruleId,
          'ruleName': rule.name,
          'trigger': rule.trigger.name,
          'rawTrigger': rule.raw['trigger'],
          'actionCount': rule.actions.length,
          'actionTypes': rule.actions.map((action) => action.type).toList(),
          ...?metadata,
        },
      ),
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
