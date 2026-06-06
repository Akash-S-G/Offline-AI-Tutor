import 'dart:async';
import 'sensor_measurement.dart';

abstract class SensorProvider {
  Stream<SensorMeasurement> get measurementStream;

  Future<void> initialize();
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
  Future<bool> isAvailable();
}
