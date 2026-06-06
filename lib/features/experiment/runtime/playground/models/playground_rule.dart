class PlaygroundRule {
  final String ruleId;
  final String name;
  final String trigger;
  final Map<String, dynamic> condition;
  final Map<String, dynamic> action;
  bool enabled;

  PlaygroundRule({
    required this.ruleId,
    required this.name,
    required this.trigger,
    required this.condition,
    required this.action,
    this.enabled = true,
  });
}
