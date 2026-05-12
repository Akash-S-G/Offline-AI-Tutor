class ClassroomPresenceCoordinator {
  final Map<String, DateTime> _presence = <String, DateTime>{};

  void markPresent(String deviceId) {
    _presence[deviceId] = DateTime.now();
  }

  void markAbsent(String deviceId) {
    _presence.remove(deviceId);
  }

  Map<String, DateTime> snapshot() => Map<String, DateTime>.from(_presence);
}
