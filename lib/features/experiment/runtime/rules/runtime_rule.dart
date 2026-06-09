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
  final String description;
  final Map<String, dynamic> raw;

  const RuntimeRule({
    required this.ruleId,
    required this.name,
    required this.trigger,
    required this.condition,
    required this.action,
    required this.description,
    required this.raw,
  });

  factory RuntimeRule.fromJson(Map<String, dynamic> json) {
    final condition = RuntimeRuleCondition.fromJson(json['condition']);
    return RuntimeRule(
      ruleId: json['ruleId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Rule',
      trigger: _triggerFromJson(json['trigger']?.toString(), condition),
      condition: condition,
      action: RuntimeRuleAction.fromJson(json['action']),
      description: json['description']?.toString() ?? '',
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => raw;

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
