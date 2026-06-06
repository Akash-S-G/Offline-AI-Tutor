// ignore_for_file: avoid_print

import '../application/experiment_device_capabilities.dart';

class ExperimentCapabilityCache {
  ExperimentDeviceCapabilities? _cachedCapabilities;

  ExperimentDeviceCapabilities? getCachedCapabilities() {
    if (_cachedCapabilities != null) {
      print('[EXPERIMENT] CAPABILITY_CACHE_HIT');
    } else {
      print('[EXPERIMENT] CAPABILITY_CACHE_MISS');
    }
    return _cachedCapabilities;
  }

  void storeCapabilities(ExperimentDeviceCapabilities capabilities) {
    _cachedCapabilities = capabilities;
  }

  void clear() {
    _cachedCapabilities = null;
  }

  void refresh() {
    print('[EXPERIMENT] CAPABILITY_CACHE_REFRESH');
    clear();
  }
}
