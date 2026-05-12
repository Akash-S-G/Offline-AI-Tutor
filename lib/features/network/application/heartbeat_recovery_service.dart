import 'classroom_session_manager.dart';

class HeartbeatRecoveryService {
  HeartbeatRecoveryService({required this.sessions});

  final ClassroomSessionManager sessions;

  Future<void> recover() async {
    if (!sessions.current.connected) {
      await sessions.register('recovered-heartbeat');
    }
    await sessions.heartbeat();
  }
}
