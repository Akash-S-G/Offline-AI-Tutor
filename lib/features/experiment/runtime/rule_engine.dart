import 'variable_store.dart';
import 'runtime_event_bus.dart';
import 'runtime_event.dart';
import 'math_evaluator_service.dart';

class RuleEngine {
  final VariableStore _variableStore;
  final RuntimeEventBus _eventBus;
  final MathEvaluatorService _mathEvaluator;
  final List<Map<String, dynamic>> _rules = [];
  
  RuleEngine(this._variableStore, this._eventBus) : _mathEvaluator = MathEvaluatorService();

  void initialize(List<Map<String, dynamic>> rulesJson) {
    _rules.clear();
    _rules.addAll(rulesJson);
  }

  void evaluateContinuousRules(double dt) {
    // Basic contextual variables
    final Map<String, dynamic> contextVars = Map.from(_variableStore.allVariables);
    contextVars['dt'] = dt;

    for (var rule in _rules) {
      if (rule['trigger'] == 'continuous' || rule['trigger'] == 'always') {
        _evaluateRule(rule, contextVars);
      }
    }
  }

  void _evaluateRule(Map<String, dynamic> rule, Map<String, dynamic> contextVars) {
    bool conditionMet = true;
    if (rule.containsKey('condition') && rule['condition'] != null) {
      final conditionStr = rule['condition'].toString();
      if (conditionStr != 'always') {
        if (rule['condition'] is Map) {
          final condMap = rule['condition'] as Map;
          final varId = condMap['variableId'];
          final op = condMap['operator'];
          final val = condMap['value'];
          
          final actualVal = _variableStore.get(varId);
          if (actualVal is num && val is num) {
            switch (op) {
              case '>': conditionMet = actualVal > val; break;
              case '<': conditionMet = actualVal < val; break;
              case '>=': conditionMet = actualVal >= val; break;
              case '<=': conditionMet = actualVal <= val; break;
              case '==': conditionMet = actualVal == val; break;
              case '!=': conditionMet = actualVal != val; break;
            }
          }
        }
      }
    }

    if (conditionMet && rule.containsKey('action')) {
      final action = rule['action'];
      if (action is String) {
        if (action.contains('=')) {
          final parts = action.split('=');
          final targetVar = parts[0].replaceAll('+', '').replaceAll('-', '').trim();
          final exprStr = parts[1].trim();
          try {
            final result = _mathEvaluator.evaluateExpression(exprStr, contextVars);
            
            final isAdd = parts[0].contains('+');
            final isSub = parts[0].contains('-');
            
            double currentVal = _variableStore.get(targetVar) ?? 0.0;
            if (isAdd) {
              _variableStore.set(targetVar, currentVal + result);
            } else if (isSub) {
              _variableStore.set(targetVar, currentVal - result);
            } else {
              _variableStore.set(targetVar, result);
            }
            
            _eventBus.emit(RuntimeEvent(
              id: 'rule_exec', 
              timestamp: DateTime.now(), 
              type: RuntimeEventType.custom, 
              message: 'RuleTriggered',
              metadata: {'ruleId': rule['ruleId']}
            ));
            _eventBus.emit(RuntimeEvent(
              id: 'var_update', 
              timestamp: DateTime.now(), 
              type: RuntimeEventType.custom, 
              message: 'VariableChanged',
              metadata: {'variableId': targetVar}
            ));
          } catch (e) {
            // print('Failed to evaluate action: $action');
          }
        }
      } else if (action is Map) {
        _eventBus.emit(RuntimeEvent(
          id: 'rule_exec', 
          timestamp: DateTime.now(), 
          type: RuntimeEventType.custom, 
          message: 'RuleTriggered',
          metadata: {'ruleId': rule['ruleId']}
        ));
      }
    }
  }
}
