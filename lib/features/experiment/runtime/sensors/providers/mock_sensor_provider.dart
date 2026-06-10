import 'dart:async';

import '../sensor_measurement.dart';
import '../sensor_provider.dart';
import '../sensor_type.dart';

class MockSensorProvider implements SensorProvider {
  final SensorType type;
  final String warning;
  final StreamController<SensorMeasurement> _controller =
      StreamController<SensorMeasurement>.broadcast();

  MockSensorProvider({required this.type, required this.warning});

  @override
  Stream<SensorMeasurement> get measurementStream => _controller.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start() async {
    _controller.add(
      SensorMeasurement(
        sensorType: type,
        timestamp: DateTime.now(),
        values: {'value': 0, 'mock': true, 'warning': warning},
        metadata: {'mock': true, 'warning': warning},
      ),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<bool> isAvailable() async => true;
}
