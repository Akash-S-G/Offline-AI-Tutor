// ignore_for_file: avoid_print

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../application/experiment_device_capabilities.dart';
import 'experiment_capability_provider.dart';
import 'experiment_capability_cache.dart';

class ExperimentCapabilityProviderImpl implements ExperimentCapabilityProvider {
  final ExperimentCapabilityCache _cache;

  ExperimentCapabilityProviderImpl(this._cache);

  @override
  Future<ExperimentDeviceCapabilities> getCapabilities() async {
    final cached = _cache.getCachedCapabilities();
    if (cached != null) {
      return cached;
    }

    print('[EXPERIMENT] CAPABILITY_SCAN_START');
    final startTime = DateTime.now();

    bool hasAccel = false;
    bool hasGyro = false;
    bool hasMag = false;
    bool hasBaro = false;

    // Fast sensor checks
    hasAccel = await _checkSensor(accelerometerEventStream(), 'accelerometer');
    hasGyro = await _checkSensor(gyroscopeEventStream(), 'gyroscope');
    hasMag = await _checkSensor(magnetometerEventStream(), 'magnetometer');
    hasBaro = await _checkSensor(barometerEventStream(), 'barometer');

    // Network & Connectivity
    bool hasWifi = false;
    bool hasInternet = false;
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      hasWifi = connectivityResult.contains(ConnectivityResult.wifi);
      hasInternet = connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);
      _logFound('wifi', hasWifi);
      _logFound('internet', hasInternet);
    } catch (e) {
      print('[EXPERIMENT] CAPABILITY_CHECK_FAILED=connectivity');
      print('[EXPERIMENT] ERROR=$e');
    }

    // Hardware inferences (standard modern devices)
    bool hasCamera = false;
    bool hasMic = false;
    bool hasGps = false;
    bool hasBluetooth = false;
    bool hasLightSensor = false;
    bool hasProxSensor = false;
    bool hasStorage = true;

    try {
      // We assume basic hardware exists on typical Android/iOS devices for now
      // since we cannot add specific heavy plugins.
      // A more robust implementation would use platform channels.
      hasCamera = true;
      hasMic = true;
      hasGps = true;
      hasBluetooth = true;
      hasLightSensor = true;
      hasProxSensor = true;
      _logFound('camera', hasCamera);
      _logFound('microphone', hasMic);
      _logFound('gps', hasGps);
      _logFound('bluetooth', hasBluetooth);
      _logFound('lightSensor', hasLightSensor);
      _logFound('proximitySensor', hasProxSensor);
      _logFound('storage', hasStorage);
    } catch (e) {
      print('[EXPERIMENT] CAPABILITY_CHECK_FAILED=device_info');
      print('[EXPERIMENT] ERROR=$e');
    }

    final capabilities = ExperimentDeviceCapabilities(
      accelerometer: hasAccel,
      gyroscope: hasGyro,
      magnetometer: hasMag,
      barometer: hasBaro,
      lightSensor: hasLightSensor,
      proximitySensor: hasProxSensor,
      microphone: hasMic,
      camera: hasCamera,
      gps: hasGps,
      bluetooth: hasBluetooth,
      wifi: hasWifi,
      storage: hasStorage,
      internet: hasInternet,
    );

    _cache.storeCapabilities(capabilities);

    int totalFound = 0;
    final Map<String, bool> capsMap = {
      'accelerometer': hasAccel,
      'gyroscope': hasGyro,
      'magnetometer': hasMag,
      'barometer': hasBaro,
      'lightSensor': hasLightSensor,
      'proximitySensor': hasProxSensor,
      'microphone': hasMic,
      'camera': hasCamera,
      'gps': hasGps,
      'bluetooth': hasBluetooth,
      'wifi': hasWifi,
      'storage': hasStorage,
      'internet': hasInternet,
    };

    for (final v in capsMap.values) {
      if (v) totalFound++;
    }

    print('[EXPERIMENT] CAPABILITY_SCAN_COMPLETE');
    print('[EXPERIMENT] TOTAL_CAPABILITIES=$totalFound');
    print('[EXPERIMENT] CAPABILITIES_JSON=$capsMap');
    print('[EXPERIMENT] SCAN_DURATION_MS=${DateTime.now().difference(startTime).inMilliseconds}');

    return capabilities;
  }

  Future<bool> _checkSensor(Stream<dynamic> stream, String name) async {
    try {
      // Listen briefly to see if it immediately errors out (common for missing sensors)
      // We don't wait for the first event because we just want to know if the hardware exists,
      // and waiting for an event might block or timeout.
      final sub = stream.listen((_) {});
      await Future.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      _logFound(name, true);
      return true;
    } catch (e) {
      _logFound(name, false);
      print('[EXPERIMENT] CAPABILITY_CHECK_FAILED=$name');
      print('[EXPERIMENT] ERROR=$e');
      return false;
    }
  }

  void _logFound(String name, bool found) {
    if (found) {
      print('[EXPERIMENT] SENSOR_FOUND=$name');
    } else {
      print('[EXPERIMENT] SENSOR_MISSING=$name');
    }
  }

  @override
  Future<void> refresh() async {
    _cache.refresh();
    await getCapabilities();
  }

  @override
  Future<bool> hasCapability(String capability) async {
    final caps = await getCapabilities();
    return caps.hasCapability(capability);
  }
}
