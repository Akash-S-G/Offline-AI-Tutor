class RuntimeRuleCondition {
  final String? variableId;
  final String operator;
  final dynamic value;

  const RuntimeRuleCondition({
    required this.variableId,
    required this.operator,
    required this.value,
  });

  factory RuntimeRuleCondition.fromJson(dynamic json) {
    if (json is Map) {
      return RuntimeRuleCondition(
        variableId: json['variableId']?.toString(),
        operator: json['operator']?.toString() ?? '==',
        value: json['value'],
      );
    }
    return const RuntimeRuleCondition(
      variableId: null,
      operator: 'always',
      value: true,
    );
  }
}
