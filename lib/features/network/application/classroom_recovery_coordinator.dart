import 'classroom_session_manager.dart';
import 'heartbeat_recovery_service.dart';
import 'session_persistence_manager.dart';

class ClassroomRecoveryCoordinator {
  ClassroomRecoveryCoordinator({
    required this.persistence,
    required this.sessions,
    required this.heartbeatRecovery,
  });

  final SessionPersistenceManager persistence;
  final ClassroomSessionManager sessions;
  final HeartbeatRecoveryService heartbeatRecovery;

  Future<bool> restoreIfNeeded(String sessionId) async {
    final saved = await persistence.loadSession(sessionId);
    if (saved == null || !persistence.isValidSession(saved)) {
      return false;
    }

    if (!sessions.current.connected || sessions.current.sessionId != sessionId) {
      await sessions.register(sessionId);
      await heartbeatRecovery.recover();
    }

    await persistence.saveSession(sessionId, <String, dynamic>{
      ...saved,
      'connected': true,
      'restoredAt': DateTime.now().toIso8601String(),
    });

    return true;
  }
}
