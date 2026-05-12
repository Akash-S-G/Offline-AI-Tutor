import 'dart:async';
import 'classroom_session_manager.dart';
import 'session_persistence_manager.dart';

enum ClassroomRecoveryStatus {
  success,
  sessionNotFound,
  sessionInvalid,
  reconnectFailed,
  persistenceError,
}

class ClassroomRecoverySnapshot {
  const ClassroomRecoverySnapshot({
    required this.status,
    required this.sessionId,
    required this.timestamp,
    this.errorMessage,
    this.restoredData,
  });

  final ClassroomRecoveryStatus status;
  final String sessionId;
  final DateTime timestamp;
  final String? errorMessage;
  final Map<String, dynamic>? restoredData;

  bool get isSuccess => status == ClassroomRecoveryStatus.success;
}

class PersistentClassroomRecoveryManager {
  PersistentClassroomRecoveryManager({
    required SessionPersistenceManager persistence,
    required ClassroomSessionManager sessions,
    this.sessionValidityThresholdHours = 72,
  })  : _persistence = persistence,
        _sessions = sessions,
        _recoveryStream = StreamController<ClassroomRecoverySnapshot>.broadcast();

  final SessionPersistenceManager _persistence;
  final ClassroomSessionManager _sessions;
  final int sessionValidityThresholdHours;
  final StreamController<ClassroomRecoverySnapshot> _recoveryStream;

  Stream<ClassroomRecoverySnapshot> get recoveryEvents => _recoveryStream.stream;

  Future<ClassroomRecoveryStatus> restoreIfNeeded(String sessionId) async {
    try {
      final saved = await _persistence.loadSession(sessionId);
      if (saved == null) {
        _recordRecovery(
          ClassroomRecoverySnapshot(
            status: ClassroomRecoveryStatus.sessionNotFound,
            sessionId: sessionId,
            timestamp: DateTime.now(),
            errorMessage: 'Session not found in persistence',
          ),
        );
        return ClassroomRecoveryStatus.sessionNotFound;
      }

      if (!_persistence.isValidSession(saved)) {
        _recordRecovery(
          ClassroomRecoverySnapshot(
            status: ClassroomRecoveryStatus.sessionInvalid,
            sessionId: sessionId,
            timestamp: DateTime.now(),
            errorMessage: 'Session failed validation',
          ),
        );
        return ClassroomRecoveryStatus.sessionInvalid;
      }

      // Validate session age
      if (saved['savedAt'] is String) {
        final savedAt = DateTime.parse(saved['savedAt'] as String);
        final age = DateTime.now().difference(savedAt);
        if (age.inHours > sessionValidityThresholdHours) {
          _recordRecovery(
            ClassroomRecoverySnapshot(
              status: ClassroomRecoveryStatus.sessionInvalid,
              sessionId: sessionId,
              timestamp: DateTime.now(),
              errorMessage:
                  'Session expired (${age.inHours}h > $sessionValidityThresholdHours threshold)',
            ),
          );
          return ClassroomRecoveryStatus.sessionInvalid;
        }
      }

      // Attempt reconnect
      try {
        if (!_sessions.current.connected || _sessions.current.sessionId != sessionId) {
          await _sessions.register(sessionId);
        }
      } catch (error) {
        _recordRecovery(
          ClassroomRecoverySnapshot(
            status: ClassroomRecoveryStatus.reconnectFailed,
            sessionId: sessionId,
            timestamp: DateTime.now(),
            errorMessage: 'Failed to reconnect: $error',
          ),
        );
        return ClassroomRecoveryStatus.reconnectFailed;
      }

      // Persist recovery marker
      try {
        await _persistence.saveSession(sessionId, <String, dynamic>{
          ...saved,
          'connected': true,
          'restoredAt': DateTime.now().toIso8601String(),
          'recoveryCount': (saved['recoveryCount'] as int? ?? 0) + 1,
        });
      } catch (error) {
        _recordRecovery(
          ClassroomRecoverySnapshot(
            status: ClassroomRecoveryStatus.persistenceError,
            sessionId: sessionId,
            timestamp: DateTime.now(),
            errorMessage: 'Failed to persist recovery: $error',
          ),
        );
        return ClassroomRecoveryStatus.persistenceError;
      }

      _recordRecovery(
        ClassroomRecoverySnapshot(
          status: ClassroomRecoveryStatus.success,
          sessionId: sessionId,
          timestamp: DateTime.now(),
          restoredData: Map<String, dynamic>.from(saved),
        ),
      );

      return ClassroomRecoveryStatus.success;
    } catch (error) {
      _recordRecovery(
        ClassroomRecoverySnapshot(
          status: ClassroomRecoveryStatus.persistenceError,
          sessionId: sessionId,
          timestamp: DateTime.now(),
          errorMessage: 'Unexpected error during recovery: $error',
        ),
      );
      return ClassroomRecoveryStatus.persistenceError;
    }
  }

  Future<Map<String, dynamic>?> getRestoredSessionData(String sessionId) async {
    final saved = await _persistence.loadSession(sessionId);
    if (saved == null) {
      return null;
    }
    return Map<String, dynamic>.from(saved);
  }

  Future<void> clearSession(String sessionId) async {
    await _persistence.clearSession(sessionId);
  }

  bool isSessionValid(Map<String, dynamic>? session) {
    if (session == null) return false;
    if (!_persistence.isValidSession(session)) return false;
    if (session['savedAt'] is! String) return false;

    final savedAt = DateTime.parse(session['savedAt'] as String);
    final age = DateTime.now().difference(savedAt);
    return age.inHours <= sessionValidityThresholdHours;
  }

  void _recordRecovery(ClassroomRecoverySnapshot snapshot) {
    _recoveryStream.add(snapshot);
  }

  void close() {
    _recoveryStream.close();
  }
}
