import '../object_registry.dart';
import '../runtime_event.dart';
import '../runtime_event_bus.dart';
import '../variable_store.dart';
import 'runtime_rule.dart';
import 'runtime_rule_action.dart';

class RuntimeActionDispatcher {
  final VariableStore variables;
  final ObjectRegistry objects;
  final RuntimeEventBus eventBus;

  RuntimeActionDispatcher({
    required this.variables,
    required this.objects,
    required this.eventBus,
  });

  bool dispatch(RuntimeRule rule) {
    var allExecuted = true;
    for (final action in rule.actions) {
      allExecuted = _dispatchAction(rule, action) && allExecuted;
    }
    return allExecuted;
  }

  bool _dispatchAction(RuntimeRule rule, RuntimeRuleAction action) {
    switch (action.type) {
      case 'show_warning':
        _showWarning(rule, action);
        return true;
      case 'hide_object':
        return _setObjectVisible(rule, action, false);
      case 'show_object':
        return _setObjectVisible(rule, action, true);
      case 'set_variable':
        return _setVariable(rule, action);
      case 'toggle_variable':
        return _toggleVariable(rule, action);
      case 'cycle_variable':
        return _cycleVariable(rule, action);
      case 'add_to_variable':
        return _addToVariable(rule, action);
      default:
        _emitActionEvent('ActionUnsupported', rule, action);
        return false;
    }
  }

  void _showWarning(RuntimeRule rule, RuntimeRuleAction action) {
    final message =
        action.payload['message']?.toString() ??
        rule.description.ifEmpty('Runtime warning');
    eventBus.emit(
      RuntimeEvent(
        id: 'warning_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.warning,
        message: message,
        metadata: {
          'ruleId': rule.ruleId,
          'ruleName': rule.name,
          'actionType': action.type,
        },
      ),
    );
    _emitActionEvent('ActionExecuted', rule, action);
  }

  bool _setObjectVisible(
    RuntimeRule rule,
    RuntimeRuleAction action,
    bool visible,
  ) {
    final objectId = action.payload['objectId']?.toString();
    if (objectId == null || objectId.isEmpty) return false;
    objects.setObjectVisible(objectId, visible);
    eventBus.emit(
      RuntimeEvent(
        id: 'object_visibility_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: visible ? 'ObjectShown' : 'ObjectHidden',
        metadata: {
          'objectId': objectId,
          'visible': visible,
          'actionType': action.type,
        },
      ),
    );
    _emitActionEvent('ActionExecuted', rule, action);
    return true;
  }

  bool _setVariable(RuntimeRule rule, RuntimeRuleAction action) {
    final variableId =
        action.payload['variableId']?.toString() ??
        action.payload['targetVariable']?.toString();
    if (variableId == null || variableId.isEmpty) return false;
    variables.updateVariable(
      variableId,
      action.payload['value'],
      source: 'rule_action',
    );
    _emitActionEvent('ActionExecuted', rule, action);
    return true;
  }

  bool _toggleVariable(RuntimeRule rule, RuntimeRuleAction action) {
    final variableId =
        action.payload['variableId']?.toString() ??
        action.payload['targetVariable']?.toString();
    if (variableId == null || variableId.isEmpty) return false;
    final current = variables.getValue(variableId);
    if (current is! bool) return false;
    variables.updateVariable(variableId, !current, source: 'rule_action');
    _emitActionEvent('ActionExecuted', rule, action);
    return true;
  }

  bool _cycleVariable(RuntimeRule rule, RuntimeRuleAction action) {
    final variableId =
        action.payload['variableId']?.toString() ??
        action.payload['targetVariable']?.toString();
    if (variableId == null || variableId.isEmpty) return false;

    final values = action.payload['values'];
    if (values is! List || values.isEmpty) return false;

    final current = variables.getValue(variableId);
    final currentIndex = values.indexOf(current);

    dynamic nextValue;
    if (currentIndex == -1 || currentIndex == values.length - 1) {
      nextValue = values.first;
    } else {
      nextValue = values[currentIndex + 1];
    }

    variables.updateVariable(variableId, nextValue, source: 'rule_action');
    _emitActionEvent('ActionExecuted', rule, action);
    return true;
  }

  bool _addToVariable(RuntimeRule rule, RuntimeRuleAction action) {
    final variableId =
        action.payload['variableId']?.toString() ??
        action.payload['targetVariable']?.toString();
    if (variableId == null || variableId.isEmpty) return false;

    final incrementValue = action.payload['value'];
    if (incrementValue is! num) return false;

    final current = variables.getValue(variableId);
    if (current is! num) return false;

    variables.updateVariable(
      variableId,
      current + incrementValue.toDouble(),
      source: 'rule_action',
    );
    _emitActionEvent('ActionExecuted', rule, action);
    return true;
  }

  void _emitActionEvent(
    String message,
    RuntimeRule rule,
    RuntimeRuleAction action,
  ) {
    eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: {
          'ruleId': rule.ruleId,
          'ruleName': rule.name,
          'actionType': action.type,
        },
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
