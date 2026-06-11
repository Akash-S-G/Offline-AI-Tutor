class PresetVariableMapping {
  final String variableId;
  final String presetPath;

  const PresetVariableMapping({
    required this.variableId,
    required this.presetPath,
  });

  factory PresetVariableMapping.fromJson(Map<String, dynamic> json) {
    return PresetVariableMapping(
      variableId: json['variableId']?.toString() ?? '',
      presetPath: json['presetPath']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'variableId': variableId, 'presetPath': presetPath};
  }
}
