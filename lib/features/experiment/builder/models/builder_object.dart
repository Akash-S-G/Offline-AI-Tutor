class BuilderObject {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> runtimeConfig;

  BuilderObject({
    required this.id,
    required this.name,
    required this.type,
    required this.properties,
    Map<String, dynamic>? runtimeConfig,
  }) : runtimeConfig = runtimeConfig ?? const {};

  factory BuilderObject.fromJson(Map<String, dynamic> json) {
    final properties = Map<String, dynamic>.from(
      json['properties'] as Map? ?? const {},
    );
    final state = Map<String, dynamic>.from(json['state'] as Map? ?? const {});
    final runtimeConfig = Map<String, dynamic>.from(
      json['runtimeConfig'] as Map? ??
          properties['runtimeConfig'] as Map? ??
          const {},
    );
    if (runtimeConfig.isEmpty) {
      runtimeConfig.addAll(_extractRuntimeConfig(json, properties, state));
    }
    return BuilderObject(
      id: json['objectId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['objectType']?.toString() ?? json['type']?.toString() ?? '',
      properties: properties,
      runtimeConfig: runtimeConfig,
    );
  }

  BuilderObject copyWith({
    String? id,
    String? name,
    String? type,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? runtimeConfig,
  }) {
    return BuilderObject(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      properties: properties ?? this.properties,
      runtimeConfig: runtimeConfig ?? this.runtimeConfig,
    );
  }

  Map<String, dynamic> toJson() {
    final mergedProperties = {
      ...properties,
      ...runtimeConfig,
      if (runtimeConfig.isNotEmpty) 'runtimeConfig': runtimeConfig,
    };
    return {
      'objectId': id,
      'objectType': type,
      'name': name,
      'properties': mergedProperties,
      'runtimeConfig': runtimeConfig,
      'state': Map<String, dynamic>.from(runtimeConfig),
    };
  }

  static Map<String, dynamic> _extractRuntimeConfig(
    Map<String, dynamic> json,
    Map<String, dynamic> properties,
    Map<String, dynamic> state,
  ) {
    final type = json['objectType']?.toString() ?? json['type']?.toString();
    dynamic read(String key) => state[key] ?? properties[key] ?? json[key];
    switch (type) {
      case 'numericDisplay':
        return {
          if (read('label') != null) 'label': read('label'),
          if (read('unit') != null) 'unit': read('unit'),
          if (read('precision') != null) 'precision': read('precision'),
        };
      case 'gauge':
        return {
          if (read('min') != null) 'min': read('min'),
          if (read('max') != null) 'max': read('max'),
          if (read('unit') != null) 'unit': read('unit'),
          if (read('warningThreshold') != null)
            'warningThreshold': read('warningThreshold'),
        };
      case 'progressBar':
        return {
          if (read('min') != null) 'min': read('min'),
          if (read('max') != null) 'max': read('max'),
        };
      case 'lineGraph':
        return {
          if (read('variableId') != null) 'variableId': read('variableId'),
          if (read('linked_variable') != null)
            'variableId': read('linked_variable'),
          if (read('historyWindow') != null)
            'historyWindow': read('historyWindow'),
          if (read('xAxis') != null) 'xAxis': read('xAxis'),
          if (read('yAxis') != null) 'yAxis': read('yAxis'),
        };
      case 'scatterPlot':
        return {
          if (read('xVariable') != null) 'xVariable': read('xVariable'),
          if (read('yVariable') != null) 'yVariable': read('yVariable'),
        };
      case 'table':
        return {
          if (read('maxRows') != null) 'maxRows': read('maxRows'),
          if (read('autoRecord') != null) 'autoRecord': read('autoRecord'),
        };
      default:
        return const {};
    }
  }
}
