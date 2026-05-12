class MultiDeviceRecoveryManager {
  final List<String> _recoveredDevices = <String>[];

  void recover(String deviceId) {
    if (!_recoveredDevices.contains(deviceId)) {
      _recoveredDevices.add(deviceId);
    }
  }

  List<String> snapshot() => List<String>.unmodifiable(_recoveredDevices);
}
