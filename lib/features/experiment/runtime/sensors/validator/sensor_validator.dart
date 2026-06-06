// ignore_for_file: avoid_print

import 'dart:async';
import '../sensor_manager.dart';
import '../sensor_type.dart';

class SensorValidator {
  Future<void> validate() async {
    print('--------------------------------------------------');
    print('SENSOR INFRASTRUCTURE VALIDATION');
    print('--------------------------------------------------');

    final manager = SensorManager();
    await manager.initialize();

    final subscription = manager.measurementStream.listen((measurement) {
      print('  -> Stream received: ${measurement.sensorType.name} values: ${measurement.values}');
    });

    print('');
    print('=== Starting Accelerometer Stream ===');
    await manager.startSensor(SensorType.accelerometer);

    // Collect 5 measurements
    await Future.delayed(const Duration(seconds: 1));

    print('=== Stopping Accelerometer Stream ===');
    await manager.stopSensor(SensorType.accelerometer);

    await Future.delayed(const Duration(milliseconds: 500));

    await subscription.cancel();
    await manager.dispose();

    print('--------------------------------------------------');
  }
}
