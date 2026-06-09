enum VariableUpdateStrategy {
  manual,
  eventDriven,
  continuous,
  timerBased,
  computed,
  unknown,
}

VariableUpdateStrategy variableUpdateStrategyFromName(String? value) {
  for (final strategy in VariableUpdateStrategy.values) {
    if (strategy.name == value) return strategy;
  }
  return VariableUpdateStrategy.unknown;
}
