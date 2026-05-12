import 'classroom_session_manager.dart';

class ReconnectCoordinator {
  ReconnectCoordinator({required this.sessions});

  final ClassroomSessionManager sessions;

  Future<void> reconnectIfNeeded() async {
    if (!sessions.current.connected) {
      await sessions.register('recovered-session');
    }
    await sessions.heartbeat();
  }
}
