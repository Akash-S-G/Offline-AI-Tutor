class ExperimentDeviceCapabilities {
  final bool accelerometer;
  final bool gyroscope;
  final bool magnetometer;
  final bool barometer;
  final bool lightSensor;
  final bool proximitySensor;
  final bool microphone;
  final bool camera;
  final bool gps;
  final bool bluetooth;
  final bool wifi;
  final bool storage;
  final bool internet;

  const ExperimentDeviceCapabilities({
    this.accelerometer = false,
    this.gyroscope = false,
    this.magnetometer = false,
    this.barometer = false,
    this.lightSensor = false,
    this.proximitySensor = false,
    this.microphone = false,
    this.camera = false,
    this.gps = false,
    this.bluetooth = false,
    this.wifi = false,
    this.storage = false,
    this.internet = false,
  });

  bool hasCapability(String capabilityName) {
    switch (capabilityName.toLowerCase()) {
      case 'accelerometer':
        return accelerometer;
      case 'gyroscope':
        return gyroscope;
      case 'magnetometer':
        return magnetometer;
      case 'barometer':
        return barometer;
      case 'lightsensor':
      case 'light':
      case 'light_sensor':
        return lightSensor;
      case 'proximitysensor':
      case 'proximity':
      case 'proximity_sensor':
        return proximitySensor;
      case 'microphone':
      case 'mic':
        return microphone;
      case 'camera':
        return camera;
      case 'gps':
      case 'location':
        return gps;
      case 'bluetooth':
        return bluetooth;
      case 'wifi':
        return wifi;
      case 'storage':
        return storage;
      case 'internet':
      case 'network':
        return internet;
      default:
        return false;
    }
  }
}
