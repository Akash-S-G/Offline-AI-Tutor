// ignore_for_file: avoid_print

import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

import '../sensor_provider.dart';
import '../sensor_measurement.dart';
import '../sensor_type.dart';

class GyroscopeProvider implements SensorProvider {
  final StreamController<SensorMeasurement> _controller = StreamController<SensorMeasurement>.broadcast();
  StreamSubscription<GyroscopeEvent>? _subscription;

  @override
  Stream<SensorMeasurement> get measurementStream => _controller.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start() async {
    print('[EXPERIMENT] PROVIDER_STARTED=gyroscope');
    _subscription = gyroscopeEventStream().listen((event) {
      _controller.add(SensorMeasurement(
        sensorType: SensorType.gyroscope,
        timestamp: DateTime.now(),
        values: {
          'x': event.x,
          'y': event.y,
          'z': event.z,
        },
      ));
    });
  }

  @override
  Future<void> stop() async {
    print('[EXPERIMENT] PROVIDER_STOPPED=gyroscope');
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final sub = gyroscopeEventStream().listen((_) {});
      await Future.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      return true;
    } catch (_) {
      return false;
    }
  }
}
