// ignore_for_file: avoid_print

import 'experiment_capability_provider.dart';

class CapabilityValidator {
  final ExperimentCapabilityProvider _provider;

  CapabilityValidator(this._provider);

  Future<void> validate() async {
    final caps = await _provider.getCapabilities();

    print('--------------------------------------------------');
    print('EXPERIMENT CAPABILITY REPORT');
    print('--------------------------------------------------');
    print('');
    print('Accelerometer: ${caps.accelerometer}');
    print('Gyroscope: ${caps.gyroscope}');
    print('Magnetometer: ${caps.magnetometer}');
    print('Barometer: ${caps.barometer}');
    print('Light Sensor: ${caps.lightSensor}');
    print('Proximity Sensor: ${caps.proximitySensor}');
    print('Microphone: ${caps.microphone}');
    print('Camera: ${caps.camera}');
    print('GPS: ${caps.gps}');
    print('Bluetooth: ${caps.bluetooth}');
    print('WiFi: ${caps.wifi}');
    print('Internet: ${caps.internet}');
    print('Storage: ${caps.storage}');
    print('');
    print('--------------------------------------------------');
  }
}
