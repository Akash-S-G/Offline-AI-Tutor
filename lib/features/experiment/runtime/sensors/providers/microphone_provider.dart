// ignore_for_file: avoid_print

import 'dart:async';

import '../sensor_provider.dart';
import '../sensor_measurement.dart';

class MicrophoneProvider implements SensorProvider {
  final StreamController<SensorMeasurement> _controller = StreamController<SensorMeasurement>.broadcast();

  @override
  Stream<SensorMeasurement> get measurementStream => _controller.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start() async {
    print('[EXPERIMENT] SENSOR_ERROR provider=microphone message=Placeholder implementation, audio recording not implemented yet');
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<bool> isAvailable() async {
    print('[EXPERIMENT] SENSOR_UNAVAILABLE=microphone (Placeholder)');
    return false;
  }
}
