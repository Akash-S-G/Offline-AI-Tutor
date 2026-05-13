import '../../../config/app_environment.dart';
import 'classroom_session_manager.dart';

class ReconnectCoordinator {
  ReconnectCoordinator({required this.sessions});

  final ClassroomSessionManager sessions;

  Future<void> reconnectIfNeeded() async {
    if (!sessions.current.connected) {
      AppEnvironment.log(
        'RECOVERY',
        'Reconnecting to classroom session',
      );
      await sessions.register('recovered-session');
    }
    await sessions.heartbeat();
  }
}
