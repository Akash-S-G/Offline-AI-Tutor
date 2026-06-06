import 'sensor_type.dart';
import 'sensor_provider.dart';
import 'providers/accelerometer_provider.dart';
import 'providers/gyroscope_provider.dart';
import 'providers/magnetometer_provider.dart';
import 'providers/barometer_provider.dart';
import 'providers/gps_provider.dart';
import 'providers/microphone_provider.dart';
import 'providers/light_provider.dart';

class SensorRegistry {
  final Map<SensorType, SensorProvider> _providers = {};

  SensorRegistry() {
    _registerDefaultProviders();
  }

  void _registerDefaultProviders() {
    _providers[SensorType.accelerometer] = AccelerometerProvider();
    _providers[SensorType.gyroscope] = GyroscopeProvider();
    _providers[SensorType.magnetometer] = MagnetometerProvider();
    _providers[SensorType.barometer] = BarometerProvider();
    _providers[SensorType.gps] = GpsProvider();
    _providers[SensorType.microphone] = MicrophoneProvider();
    _providers[SensorType.light] = LightProvider();
  }

  SensorProvider? getProvider(SensorType type) {
    return _providers[type];
  }

  Future<bool> isAvailable(SensorType type) async {
    final provider = _providers[type];
    if (provider == null) return false;
    return await provider.isAvailable();
  }

  Future<List<SensorType>> getAvailableSensors() async {
    final available = <SensorType>[];
    for (final entry in _providers.entries) {
      if (await entry.value.isAvailable()) {
        available.add(entry.key);
      }
    }
    return available;
  }
}
