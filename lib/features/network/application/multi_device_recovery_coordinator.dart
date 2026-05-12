import 'dart:async';

class DevicePresence {
  const DevicePresence({
    required this.deviceId,
    required this.lastSeen,
    required this.isOnline,
  });

  final String deviceId;
  final DateTime lastSeen;
  final bool isOnline;

  bool get isStale => DateTime.now().difference(lastSeen).inSeconds > 60;
}

class ClassroomDeviceSnapshot {
  const ClassroomDeviceSnapshot({
    required this.totalDevices,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.timestamp,
  });

  final int totalDevices;
  final int onlineDevices;
  final int offlineDevices;
  final DateTime timestamp;

  double get availabilityPercent =>
      totalDevices == 0 ? 0 : (onlineDevices / totalDevices) * 100;
}

class MultiDeviceRecoveryCoordinator {
  MultiDeviceRecoveryCoordinator({
    this.presenceTimeoutSeconds = 60,
    this.maxRecoveryAttempts = 3,
  })  : _deviceStream = StreamController<ClassroomDeviceSnapshot>.broadcast();

  final int presenceTimeoutSeconds;
  final int maxRecoveryAttempts;
  final Map<String, DevicePresence> _devices = <String, DevicePresence>{};
  final Map<String, int> _recoveryAttempts = <String, int>{};
  final StreamController<ClassroomDeviceSnapshot> _deviceStream;
  Timer? _presenceMonitor;

  Stream<ClassroomDeviceSnapshot> get deviceUpdates => _deviceStream.stream;

  void registerDevice(String deviceId) {
    _devices[deviceId] = DevicePresence(
      deviceId: deviceId,
      lastSeen: DateTime.now(),
      isOnline: true,
    );
    _recoveryAttempts.putIfAbsent(deviceId, () => 0);
    _publishSnapshot();
  }

  void markOnline(String deviceId) {
    final existing = _devices[deviceId];
    _devices[deviceId] = DevicePresence(
      deviceId: deviceId,
      lastSeen: DateTime.now(),
      isOnline: true,
    );
    _recoveryAttempts[deviceId] = 0;
    _publishSnapshot();
  }

  void markOffline(String deviceId) {
    final existing = _devices[deviceId];
    if (existing != null) {
      _devices[deviceId] = DevicePresence(
        deviceId: deviceId,
        lastSeen: existing.lastSeen,
        isOnline: false,
      );
    }
    _publishSnapshot();
  }

  void recordRecoveryAttempt(String deviceId) {
    _recoveryAttempts[deviceId] = (_recoveryAttempts[deviceId] ?? 0) + 1;
  }

  bool canAttemptRecovery(String deviceId) {
    final attempts = _recoveryAttempts[deviceId] ?? 0;
    return attempts < maxRecoveryAttempts;
  }

  List<DevicePresence> getOfflineDevices() {
    return _devices.values.where((d) => !d.isOnline).toList();
  }

  List<DevicePresence> getOnlineDevices() {
    return _devices.values.where((d) => d.isOnline).toList();
  }

  List<DevicePresence> getDevicesRequiringRecovery() {
    return _devices.values
        .where((d) => !d.isOnline && canAttemptRecovery(d.deviceId))
        .toList();
  }

  void startPresenceMonitoring() {
    _presenceMonitor = Timer.periodic(
      Duration(seconds: 10),
      (_) => _checkPresenceTimeouts(),
    );
  }

  void stopPresenceMonitoring() {
    _presenceMonitor?.cancel();
    _presenceMonitor = null;
  }

  void _checkPresenceTimeouts() {
    final now = DateTime.now();
    for (final device in _devices.values) {
      if (device.isOnline &&
          now.difference(device.lastSeen).inSeconds > presenceTimeoutSeconds) {
        markOffline(device.deviceId);
      }
    }
  }

  void _publishSnapshot() {
    final online = getOnlineDevices();
    final offline = getOfflineDevices();
    _deviceStream.add(
      ClassroomDeviceSnapshot(
        totalDevices: _devices.length,
        onlineDevices: online.length,
        offlineDevices: offline.length,
        timestamp: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> getClassroomStatus() {
    final online = getOnlineDevices();
    final offline = getOfflineDevices();
    return {
      'totalDevices': _devices.length,
      'onlineDevices': online.length,
      'offlineDevices': offline.length,
      'availabilityPercent': online.isEmpty && offline.isEmpty
          ? 0.0
          : (online.length / _devices.length) * 100,
      'devicesRequiringRecovery': getDevicesRequiringRecovery().length,
    };
  }

  void clear() {
    _devices.clear();
    _recoveryAttempts.clear();
    _publishSnapshot();
  }

  void close() {
    stopPresenceMonitoring();
    _deviceStream.close();
  }
}
