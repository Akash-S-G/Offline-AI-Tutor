import 'dart:async';

class ClassroomSessionState {
  const ClassroomSessionState({required this.connected, this.sessionId, this.lastHeartbeat});
  final bool connected;
  final String? sessionId;
  final DateTime? lastHeartbeat;
}

class ClassroomSessionManager {
  ClassroomSessionManager();

  final StreamController<ClassroomSessionState> _state = StreamController<ClassroomSessionState>.broadcast();
  ClassroomSessionState _current = const ClassroomSessionState(connected: false);

  Stream<ClassroomSessionState> get states => _state.stream;
  ClassroomSessionState get current => _current;

  Future<void> register(String sessionId) async {
    _current = ClassroomSessionState(connected: true, sessionId: sessionId, lastHeartbeat: DateTime.now());
    _state.add(_current);
  }

  Future<void> heartbeat() async {
    if (!_current.connected) return;
    _current = ClassroomSessionState(
      connected: true,
      sessionId: _current.sessionId,
      lastHeartbeat: DateTime.now(),
    );
    _state.add(_current);
  }

  Future<void> disconnect() async {
    _current = const ClassroomSessionState(connected: false);
    _state.add(_current);
  }

  Future<void> close() async {
    await _state.close();
  }
}
