import 'runtime_rule.dart';

class RuntimeRuleState {
  final RuntimeRule rule;
  final bool active;
  final DateTime? lastEvaluation;
  final bool? lastResult;
  final int fireCount;

  const RuntimeRuleState({
    required this.rule,
    required this.active,
    this.lastEvaluation,
    this.lastResult,
    this.fireCount = 0,
  });

  RuntimeRuleState copyWith({
    bool? active,
    DateTime? lastEvaluation,
    bool? lastResult,
    int? fireCount,
  }) {
    return RuntimeRuleState(
      rule: rule,
      active: active ?? this.active,
      lastEvaluation: lastEvaluation ?? this.lastEvaluation,
      lastResult: lastResult ?? this.lastResult,
      fireCount: fireCount ?? this.fireCount,
    );
  }
}

class RuntimeRuleRegistry {
  final Map<String, RuntimeRuleState> _states = {};

  void registerRule(RuntimeRule rule) {
    _states[rule.ruleId] = RuntimeRuleState(rule: rule, active: false);
  }

  void activateRule(String ruleId) {
    final state = _states[ruleId];
    if (state == null) return;
    _states[ruleId] = state.copyWith(active: true);
  }

  RuntimeRuleState? getState(String ruleId) => _states[ruleId];

  List<RuntimeRule> get rules =>
      _states.values.map((state) => state.rule).toList(growable: false);

  List<RuntimeRuleState> get states => _states.values.toList(growable: false);

  void recordEvaluation(String ruleId, bool result) {
    final state = _states[ruleId];
    if (state == null) return;
    _states[ruleId] = state.copyWith(
      lastEvaluation: DateTime.now(),
      lastResult: result,
      fireCount: result ? state.fireCount + 1 : state.fireCount,
    );
  }

  void clear() {
    _states.clear();
  }
}
