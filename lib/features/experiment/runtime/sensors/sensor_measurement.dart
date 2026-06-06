import 'sensor_type.dart';

class SensorMeasurement {
  final SensorType sensorType;
  final DateTime timestamp;
  final Map<String, dynamic> values;
  final Map<String, dynamic>? metadata;

  SensorMeasurement({
    required this.sensorType,
    required this.timestamp,
    required this.values,
    this.metadata,
  });
}
