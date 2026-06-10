import '../sensor_type.dart';

enum RuntimeSensorType {
  accelerometer,
  gyroscope,
  magnetometer,
  gps,
  light,
  proximity,
  microphone,
  barometer,
}

extension RuntimeSensorTypeX on RuntimeSensorType {
  SensorType get providerType {
    switch (this) {
      case RuntimeSensorType.accelerometer:
        return SensorType.accelerometer;
      case RuntimeSensorType.gyroscope:
        return SensorType.gyroscope;
      case RuntimeSensorType.magnetometer:
        return SensorType.magnetometer;
      case RuntimeSensorType.gps:
        return SensorType.gps;
      case RuntimeSensorType.light:
        return SensorType.light;
      case RuntimeSensorType.proximity:
        return SensorType.proximity;
      case RuntimeSensorType.microphone:
        return SensorType.microphone;
      case RuntimeSensorType.barometer:
        return SensorType.barometer;
    }
  }

  String get variableType {
    switch (this) {
      case RuntimeSensorType.light:
        return 'lightSensor';
      default:
        return name;
    }
  }
}

RuntimeSensorType? runtimeSensorTypeFromVariableType(String type) {
  switch (type) {
    case 'accelerometer':
      return RuntimeSensorType.accelerometer;
    case 'gyroscope':
      return RuntimeSensorType.gyroscope;
    case 'magnetometer':
      return RuntimeSensorType.magnetometer;
    case 'gps':
      return RuntimeSensorType.gps;
    case 'light':
    case 'lightSensor':
      return RuntimeSensorType.light;
    case 'proximity':
      return RuntimeSensorType.proximity;
    case 'microphone':
      return RuntimeSensorType.microphone;
    case 'barometer':
      return RuntimeSensorType.barometer;
    default:
      return null;
  }
}
