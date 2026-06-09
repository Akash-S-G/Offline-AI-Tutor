class RuntimeExperimentMetrics {
  final int variables;
  final int objects;
  final int rules;
  final int measurements;
  final int observations;
  final int warnings;
  final int rulesTriggered;
  final int graphUpdates;
  final int sensorUpdates;

  const RuntimeExperimentMetrics({
    required this.variables,
    required this.objects,
    required this.rules,
    required this.measurements,
    required this.observations,
    required this.warnings,
    required this.rulesTriggered,
    required this.graphUpdates,
    required this.sensorUpdates,
  });

  const RuntimeExperimentMetrics.empty()
    : variables = 0,
      objects = 0,
      rules = 0,
      measurements = 0,
      observations = 0,
      warnings = 0,
      rulesTriggered = 0,
      graphUpdates = 0,
      sensorUpdates = 0;

  RuntimeExperimentMetrics copyWith({
    int? variables,
    int? objects,
    int? rules,
    int? measurements,
    int? observations,
    int? warnings,
    int? rulesTriggered,
    int? graphUpdates,
    int? sensorUpdates,
  }) {
    return RuntimeExperimentMetrics(
      variables: variables ?? this.variables,
      objects: objects ?? this.objects,
      rules: rules ?? this.rules,
      measurements: measurements ?? this.measurements,
      observations: observations ?? this.observations,
      warnings: warnings ?? this.warnings,
      rulesTriggered: rulesTriggered ?? this.rulesTriggered,
      graphUpdates: graphUpdates ?? this.graphUpdates,
      sensorUpdates: sensorUpdates ?? this.sensorUpdates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variables': variables,
      'objects': objects,
      'rules': rules,
      'measurements': measurements,
      'observations': observations,
      'warnings': warnings,
      'rulesTriggered': rulesTriggered,
      'graphUpdates': graphUpdates,
      'sensorUpdates': sensorUpdates,
    };
  }
}
