enum VariableSource { manual, constant, sensor, timer, computed, unknown }

VariableSource variableSourceFromName(String? value) {
  for (final source in VariableSource.values) {
    if (source.name == value) return source;
  }
  return VariableSource.unknown;
}
