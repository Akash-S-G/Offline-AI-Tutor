enum StepType {
  instruction,
  interaction,
  observation,
  analysis,
  question,
  completion,
}

StepType stepTypeFromString(String? value) {
  return StepType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => StepType.instruction,
  );
}
