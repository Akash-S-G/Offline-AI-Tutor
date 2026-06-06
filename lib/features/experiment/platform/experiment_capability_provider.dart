import '../application/experiment_device_capabilities.dart';

abstract class ExperimentCapabilityProvider {
  Future<ExperimentDeviceCapabilities> getCapabilities();
  Future<void> refresh();
  Future<bool> hasCapability(String capability);
}
