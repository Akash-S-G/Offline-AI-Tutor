// ignore_for_file: avoid_print

import 'dart:async';
import 'sensor_type.dart';
import 'sensor_measurement.dart';
import 'sensor_registry.dart';

class SensorManager {
  final SensorRegistry _registry = SensorRegistry();
  final Map<SensorType, StreamSubscription<SensorMeasurement>> _subscriptions =
      {};

  final StreamController<SensorMeasurement> _measurementController =
      StreamController<SensorMeasurement>.broadcast();
  Stream<SensorMeasurement> get measurementStream =>
      _measurementController.stream;

  Future<void> initialize() async {
    print('[EXPERIMENT] SENSOR_MANAGER_INIT');
    final available = await _registry.getAvailableSensors();
    for (final sensor in available) {
      print('[EXPERIMENT] SENSOR_AVAILABLE=${sensor.name}');
    }

    // Also log unavailable for those not in the list
    for (final type in SensorType.values) {
      if (!available.contains(type)) {
        print('[EXPERIMENT] SENSOR_UNAVAILABLE=${type.name}');
      }
    }
  }

  Future<void> startSensor(SensorType type) async {
    final provider = _registry.getProvider(type);
    if (provider == null) {
      print(
        '[EXPERIMENT] SENSOR_ERROR provider=${type.name} message=Provider not found',
      );
      return;
    }

    if (!await provider.isAvailable()) {
      print(
        '[EXPERIMENT] SENSOR_ERROR provider=${type.name} message=Sensor is unavailable',
      );
      return;
    }

    await provider.start();
    _subscriptions[type] = provider.measurementStream.listen(
      (measurement) {
        print('[EXPERIMENT] MEASUREMENT_RECEIVED sensor=${type.name}');
        _measurementController.add(measurement);
      },
      onError: (e) {
        print('[EXPERIMENT] SENSOR_ERROR provider=${type.name} message=$e');
      },
    );
  }

  Future<void> stopSensor(SensorType type) async {
    await _subscriptions[type]?.cancel();
    _subscriptions.remove(type);

    final provider = _registry.getProvider(type);
    await provider?.stop();
  }

  Future<void> dispose() async {
    for (final sub in _subscriptions.values) {
      await sub.cancel();
    }
    _subscriptions.clear();

    for (final type in SensorType.values) {
      await _registry.getProvider(type)?.dispose();
    }
    await _measurementController.close();
  }
}
