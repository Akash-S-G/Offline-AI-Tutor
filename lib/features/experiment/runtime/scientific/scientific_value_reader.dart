import 'dart:math' as math;

double numericValue(dynamic value, {String? field}) {
  if (value is num) return value.toDouble();
  if (value is Map) {
    if (field != null && field.isNotEmpty) {
      final fieldValue = value[field];
      if (fieldValue is num) return fieldValue.toDouble();
      return double.tryParse(fieldValue?.toString() ?? '') ?? 0;
    }
    for (final key in const [
      'magnitude',
      'value',
      'amplitude',
      'lux',
      'distance',
      'accuracy',
      'speed',
      'altitude',
      'latitude',
    ]) {
      final entry = value[key];
      if (entry is num) return entry.toDouble();
    }
    final x = value['x'];
    final y = value['y'];
    final z = value['z'];
    if (x is num && y is num && z is num) {
      return math.sqrt(x * x + y * y + z * z);
    }
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double propertyDouble(Map<String, dynamic> map, String key, double fallback) {
  final value = map[key];
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int propertyInt(Map<String, dynamic> map, String key, int fallback) {
  final value = map[key];
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

Map<String, dynamic> objectProperties(Map<String, dynamic> objectJson) {
  final properties = Map<String, dynamic>.from(
    objectJson['properties'] as Map? ?? const {},
  );
  final config = Map<String, dynamic>.from(
    objectJson['runtimeConfig'] as Map? ??
        properties['runtimeConfig'] as Map? ??
        const {},
  );
  return {...properties, ...config, ...objectJson};
}
