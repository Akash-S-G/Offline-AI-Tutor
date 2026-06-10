// ignore_for_file: avoid_print

import 'dart:async';
import 'package:geolocator/geolocator.dart';

import '../sensor_provider.dart';
import '../sensor_measurement.dart';
import '../sensor_type.dart';

class GpsProvider implements SensorProvider {
  final StreamController<SensorMeasurement> _controller =
      StreamController<SensorMeasurement>.broadcast();
  StreamSubscription<Position>? _subscription;

  @override
  Stream<SensorMeasurement> get measurementStream => _controller.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start() async {
    print('[EXPERIMENT] PROVIDER_STARTED=gps');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('[EXPERIMENT] SENSOR_ERROR provider=gps message=Permission denied');
      return;
    }

    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).listen(
          (Position position) {
            _controller.add(
              SensorMeasurement(
                sensorType: SensorType.gps,
                timestamp: DateTime.now(),
                values: {
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                  'accuracy': position.accuracy,
                  'speed': position.speed,
                  'altitude': position.altitude,
                },
              ),
            );
          },
          onError: (e) {
            print('[EXPERIMENT] SENSOR_ERROR provider=gps message=$e');
          },
        );
  }

  @override
  Future<void> stop() async {
    print('[EXPERIMENT] PROVIDER_STOPPED=gps');
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
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }
}
