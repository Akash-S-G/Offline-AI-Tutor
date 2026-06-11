class ExperimentParameter {
  final String id;
  final String displayName;
  final String variableId;
  final String unit;
  final double minValue;
  final double maxValue;
  final double defaultValue;
  final String controlType;
  final String description;

  const ExperimentParameter({
    required this.id,
    required this.displayName,
    required this.variableId,
    this.unit = '',
    this.minValue = 0,
    this.maxValue = 100,
    this.defaultValue = 0,
    this.controlType = 'slider',
    this.description = '',
  });

  factory ExperimentParameter.fromJson(Map<String, dynamic> json) {
    return ExperimentParameter(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Parameter',
      variableId: json['variableId']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      minValue: _double(json['minValue'], 0),
      maxValue: _double(json['maxValue'], 100),
      defaultValue: _double(json['defaultValue'], 0),
      controlType: json['controlType']?.toString() ?? 'slider',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'variableId': variableId,
      'unit': unit,
      'minValue': minValue,
      'maxValue': maxValue,
      'defaultValue': defaultValue,
      'controlType': controlType,
      'description': description,
    };
  }

  static double _double(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
