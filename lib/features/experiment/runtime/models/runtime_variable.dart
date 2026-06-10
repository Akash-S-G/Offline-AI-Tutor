import 'variable_source.dart';
import 'variable_update_strategy.dart';

class RuntimeVariable {
  static const Object _unset = Object();

  final String id;
  final String name;
  final String type;
  final dynamic value;
  final VariableSource source;
  final VariableUpdateStrategy updateStrategy;
  final Map<String, dynamic> metadata;
  final DateTime lastUpdated;
  final bool isInitialized;

  const RuntimeVariable({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.source,
    required this.updateStrategy,
    required this.metadata,
    required this.lastUpdated,
    required this.isInitialized,
  });

  factory RuntimeVariable.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? 'manual';
    final metadata = <String, dynamic>{
      if (json['metadata'] is Map)
        ...Map<String, dynamic>.from(json['metadata'] as Map),
    };
    metadata.addAll(
      Map<String, dynamic>.from(json)
        ..remove('id')
        ..remove('variableId')
        ..remove('name')
        ..remove('type')
        ..remove('value')
        ..remove('source')
        ..remove('updateStrategy')
        ..remove('lastUpdated')
        ..remove('isInitialized')
        ..remove('metadata'),
    );
    final lastUpdatedValue = json['lastUpdated'];

    return RuntimeVariable(
      id: json['id']?.toString() ?? json['variableId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['id']?.toString() ?? 'Variable',
      type: type,
      value: json['value'],
      source: json.containsKey('source')
          ? variableSourceFromName(json['source']?.toString())
          : sourceForType(type),
      updateStrategy: json.containsKey('updateStrategy')
          ? variableUpdateStrategyFromName(json['updateStrategy']?.toString())
          : updateStrategyForType(type),
      metadata: metadata,
      lastUpdated: lastUpdatedValue is String
          ? DateTime.tryParse(lastUpdatedValue) ?? DateTime.now()
          : DateTime.now(),
      isInitialized: json['isInitialized'] == false ? false : true,
    );
  }

  RuntimeVariable copyWith({
    String? id,
    String? name,
    String? type,
    Object? value = _unset,
    VariableSource? source,
    VariableUpdateStrategy? updateStrategy,
    Map<String, dynamic>? metadata,
    DateTime? lastUpdated,
    bool? isInitialized,
  }) {
    return RuntimeVariable(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: identical(value, _unset) ? this.value : value,
      source: source ?? this.source,
      updateStrategy: updateStrategy ?? this.updateStrategy,
      metadata: metadata ?? this.metadata,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'source': source.name,
      'updateStrategy': updateStrategy.name,
      'metadata': metadata,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isInitialized': isInitialized,
    };
  }

  String debugDescription() {
    return '$name ($id) type=$type value=$value source=${source.name} '
        'strategy=${updateStrategy.name} initialized=$isInitialized';
  }

  @override
  bool operator ==(Object other) {
    return other is RuntimeVariable &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.value == value &&
        other.source == source &&
        other.updateStrategy == updateStrategy &&
        other.isInitialized == isInitialized &&
        _mapsEqual(other.metadata, metadata) &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    value,
    source,
    updateStrategy,
    metadata.length,
    lastUpdated,
    isInitialized,
  );

  static VariableSource sourceForType(String type) {
    const sensorTypes = {
      'accelerometer',
      'gyroscope',
      'magnetometer',
      'gps',
      'microphone',
      'lightSensor',
      'proximity',
      'barometer',
    };
    const timerTypes = {'elapsedTime', 'countdown', 'interval'};
    const computedTypes = {
      'average',
      'minimum',
      'maximum',
      'velocity',
      'acceleration',
      'distance',
      'force',
      'power',
      'energy',
    };

    if (type == 'customConstant') return VariableSource.constant;
    if (sensorTypes.contains(type)) return VariableSource.sensor;
    if (timerTypes.contains(type)) return VariableSource.timer;
    if (computedTypes.contains(type)) return VariableSource.computed;
    if (_manualTypes.contains(type)) return VariableSource.manual;
    return VariableSource.unknown;
  }

  static VariableUpdateStrategy updateStrategyForType(String type) {
    const continuousTypes = {
      'accelerometer',
      'gyroscope',
      'magnetometer',
      'gps',
      'lightSensor',
      'proximity',
      'microphone',
      'barometer',
    };
    const timerTypes = {'elapsedTime', 'countdown', 'interval'};
    const computedTypes = {
      'average',
      'minimum',
      'maximum',
      'velocity',
      'acceleration',
      'distance',
      'force',
      'power',
      'energy',
    };
    if (timerTypes.contains(type)) {
      return VariableUpdateStrategy.timerBased;
    }
    if (computedTypes.contains(type)) {
      return VariableUpdateStrategy.computed;
    }
    if (continuousTypes.contains(type)) {
      return VariableUpdateStrategy.continuous;
    }
    if (type == 'customConstant') return VariableUpdateStrategy.manual;
    if (_manualTypes.contains(type)) return VariableUpdateStrategy.eventDriven;
    return VariableUpdateStrategy.unknown;
  }

  static const Set<String> _manualTypes = {
    'slider',
    'textInput',
    'numberInput',
    'dropdown',
    'toggle',
    'manual',
  };

  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
