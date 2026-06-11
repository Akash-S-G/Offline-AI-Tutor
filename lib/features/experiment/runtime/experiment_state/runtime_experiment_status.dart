enum RuntimeExperimentStatus {
  created,
  prepared,
  running,
  paused,
  completed,
  failed,
  stopped,
}

RuntimeExperimentStatus runtimeExperimentStatusFromName(String? name) {
  return RuntimeExperimentStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => RuntimeExperimentStatus.created,
  );
}
