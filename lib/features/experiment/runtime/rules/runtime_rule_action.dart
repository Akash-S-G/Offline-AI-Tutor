class RuntimeRuleAction {
  final String type;
  final Map<String, dynamic> payload;

  const RuntimeRuleAction({required this.type, required this.payload});

  factory RuntimeRuleAction.fromJson(dynamic json) {
    if (json is Map) {
      final payload = Map<String, dynamic>.from(json);
      final type = payload['type']?.toString() ?? 'show_warning';
      return RuntimeRuleAction(type: type, payload: payload);
    }
    if (json is String) {
      return RuntimeRuleAction(
        type: 'set_variable_expression',
        payload: {'expression': json},
      );
    }
    return const RuntimeRuleAction(type: 'noop', payload: {});
  }
}
