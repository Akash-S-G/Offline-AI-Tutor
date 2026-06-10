import 'runtime_rule_action.dart';
import 'runtime_rule_condition.dart';

enum RuntimeRuleTrigger {
  variableChanged,
  continuous,
  always,
  objectInteraction,
  manual,
}

class RuntimeRule {
  final String ruleId;
  final String name;
  final RuntimeRuleTrigger trigger;
  final RuntimeRuleCondition condition;
  final RuntimeRuleAction action;
  final List<RuntimeRuleAction> actions;
  final String description;
  final Map<String, dynamic> raw;

  const RuntimeRule({
    required this.ruleId,
    required this.name,
    required this.trigger,
    required this.condition,
    required this.action,
    required this.actions,
    required this.description,
    required this.raw,
  });

  factory RuntimeRule.fromJson(Map<String, dynamic> json) {
    final condition = RuntimeRuleCondition.fromJson(json['condition']);
    final actions = _actionsFromJson(json);
    return RuntimeRule(
      ruleId: json['ruleId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Rule',
      trigger: _triggerFromJson(json['trigger']?.toString(), condition),
      condition: condition,
      action: actions.isEmpty
          ? RuntimeRuleAction.fromJson(json['action'])
          : actions.first,
      actions: actions.isEmpty
          ? [RuntimeRuleAction.fromJson(json['action'])]
          : actions,
      description: json['description']?.toString() ?? '',
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => raw;

  static List<RuntimeRuleAction> _actionsFromJson(Map<String, dynamic> json) {
    final actionsJson = json['actions'];
    if (actionsJson is List) {
      return actionsJson
          .map(RuntimeRuleAction.fromJson)
          .where((action) => action.type != 'noop')
          .toList(growable: false);
    }
    final action = RuntimeRuleAction.fromJson(json['action']);
    return action.type == 'noop' ? const [] : [action];
  }

  static RuntimeRuleTrigger _triggerFromJson(
    String? trigger,
    RuntimeRuleCondition condition,
  ) {
    switch (trigger) {
      case 'variableChanged':
      case 'variable_changed':
        return RuntimeRuleTrigger.variableChanged;
      case 'continuous':
        return RuntimeRuleTrigger.continuous;
      case 'always':
        return RuntimeRuleTrigger.always;
      case 'objectInteraction':
      case 'buttonEvent':
      case 'sliderEvent':
        return RuntimeRuleTrigger.objectInteraction;
      case 'manual':
        return RuntimeRuleTrigger.manual;
      case 'any':
      case null:
        return condition.variableId == null
            ? RuntimeRuleTrigger.always
            : RuntimeRuleTrigger.variableChanged;
      default:
        return condition.variableId == null
            ? RuntimeRuleTrigger.manual
            : RuntimeRuleTrigger.variableChanged;
    }
  }
}
