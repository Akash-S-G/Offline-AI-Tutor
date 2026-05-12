import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ClassroomStateRecoveryStatus {
  success,
  stateNotFound,
  stateInvalid,
  partialRestore,
  persistenceError,
}

/// Represents complete classroom state for recovery
class ClassroomStateSnapshot {
  final String? sessionId;
  final String? currentTopic;
  final String? currentChapter;
  final List<Map<String, dynamic>>? messageHistory;
  final Map<String, dynamic>? studentProgress;
  final Map<String, dynamic>? deviceSyncState;
  final Map<String, dynamic>? manifestStatus;
  final DateTime capturedAt;
  final int? recoveryChecksum;

  ClassroomStateSnapshot({
    this.sessionId,
    this.currentTopic,
    this.currentChapter,
    this.messageHistory,
    this.studentProgress,
    this.deviceSyncState,
    this.manifestStatus,
    required this.capturedAt,
    this.recoveryChecksum,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'currentTopic': currentTopic,
    'currentChapter': currentChapter,
    'messageHistory': messageHistory,
    'studentProgress': studentProgress,
    'deviceSyncState': deviceSyncState,
    'manifestStatus': manifestStatus,
    'capturedAt': capturedAt.toIso8601String(),
    'recoveryChecksum': recoveryChecksum,
  };

  factory ClassroomStateSnapshot.fromJson(Map<String, dynamic> json) =>
      ClassroomStateSnapshot(
        sessionId: json['sessionId'] as String?,
        currentTopic: json['currentTopic'] as String?,
        currentChapter: json['currentChapter'] as String?,
        messageHistory: (json['messageHistory'] as List?)
            ?.cast<Map<String, dynamic>>(),
        studentProgress: json['studentProgress'] as Map<String, dynamic>?,
        deviceSyncState: json['deviceSyncState'] as Map<String, dynamic>?,
        manifestStatus: json['manifestStatus'] as Map<String, dynamic>?,
        capturedAt: DateTime.parse(
          json['capturedAt'] as String? ?? DateTime.now().toIso8601String(),
        ),
        recoveryChecksum: json['recoveryChecksum'] as int?,
      );
}

/// Event representing classroom state recovery attempt
class ClassroomStateRecoveryEvent {
  final ClassroomStateRecoveryStatus status;
  final DateTime timestamp;
  final ClassroomStateSnapshot? restoredState;
  final String? errorMessage;
  final List<String>? restoredComponents;

  ClassroomStateRecoveryEvent({
    required this.status,
    required this.timestamp,
    this.restoredState,
    this.errorMessage,
    this.restoredComponents,
  });
}

/// Comprehensive classroom state persistence and recovery coordinator
class ClassroomStatePersistence {
  static const String _stateKey = 'classroom_state_snapshot';
  static const String _timestampKey = 'classroom_state_timestamp';
  static const String _checksumKey = 'classroom_state_checksum';
  static const int _maxStateAge = 12 * 60 * 60 * 1000; // 12 hours
  static const int _maxRecoveryAttempts = 3;

  final Map<String, dynamic> _inMemoryState = <String, dynamic>{};
  final StreamController<ClassroomStateRecoveryEvent> _recoveryEvents =
      StreamController<ClassroomStateRecoveryEvent>.broadcast();

  late SharedPreferences _prefs;
  bool _initialized = false;
  int _recoveryAttemptCount = 0;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Capture and persist complete classroom state
  Future<void> captureState(ClassroomStateSnapshot state) async {
    try {
      if (!_initialized) await initialize();

      // Calculate checksum for validation
      final checksum = _calculateChecksum(state);

      // Serialize
      final stateJson = jsonEncode(state.toJson()..['recoveryChecksum'] = checksum);

      // Persist
      await Future.wait([
        _prefs.setString(_stateKey, stateJson),
        _prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch),
        _prefs.setInt(_checksumKey, checksum),
      ]);

      // Cache in memory
      _inMemoryState['lastCapture'] = state;
      _inMemoryState['captureTime'] = DateTime.now();
    } catch (e) {
      _broadcastRecoveryEvent(
        ClassroomStateRecoveryStatus.persistenceError,
        errorMessage: 'Failed to capture state: $e',
      );
    }
  }

  /// Restore classroom state from persistence
  Future<ClassroomStateRecoveryStatus> restoreState() async {
    try {
      if (!_initialized) await initialize();

      // Check recovery attempts
      if (_recoveryAttemptCount >= _maxRecoveryAttempts) {
        _broadcastRecoveryEvent(
          ClassroomStateRecoveryStatus.stateInvalid,
          errorMessage: 'Max recovery attempts exceeded',
        );
        return ClassroomStateRecoveryStatus.stateInvalid;
      }
      _recoveryAttemptCount++;

      // Load persisted state
      final stateJson = _prefs.getString(_stateKey);
      if (stateJson == null) {
        _broadcastRecoveryEvent(ClassroomStateRecoveryStatus.stateNotFound);
        return ClassroomStateRecoveryStatus.stateNotFound;
      }

      // Parse
      final parsed = jsonDecode(stateJson) as Map<String, dynamic>;
      final restoredChecksum = parsed['recoveryChecksum'] as int?;
      final snapshot = ClassroomStateSnapshot.fromJson(parsed);

      // Validate age
      final timestamp = _prefs.getInt(_timestampKey) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > _maxStateAge) {
        _broadcastRecoveryEvent(
          ClassroomStateRecoveryStatus.stateInvalid,
          errorMessage: 'State too old (${age}ms). Maximum age: ${_maxStateAge}ms',
        );
        return ClassroomStateRecoveryStatus.stateInvalid;
      }

      // Validate checksum
      final expectedChecksum = _calculateChecksum(snapshot);
      if (restoredChecksum != expectedChecksum) {
        _broadcastRecoveryEvent(
          ClassroomStateRecoveryStatus.stateInvalid,
          errorMessage: 'Checksum mismatch. Data may be corrupted.',
        );
        return ClassroomStateRecoveryStatus.stateInvalid;
      }

      // Determine what was successfully restored
      final restoredComponents = <String>[];
      if (snapshot.sessionId != null) restoredComponents.add('sessionId');
      if (snapshot.currentTopic != null) restoredComponents.add('topic');
      if (snapshot.currentChapter != null) restoredComponents.add('chapter');
      if (snapshot.messageHistory != null && snapshot.messageHistory!.isNotEmpty) {
        restoredComponents.add('messageHistory');
      }
      if (snapshot.studentProgress != null) restoredComponents.add('progress');
      if (snapshot.deviceSyncState != null) restoredComponents.add('deviceSync');
      if (snapshot.manifestStatus != null) restoredComponents.add('manifest');

      // Cache in memory
      _inMemoryState['restoredState'] = snapshot;
      _inMemoryState['restoreTime'] = DateTime.now();

      _broadcastRecoveryEvent(
        ClassroomStateRecoveryStatus.success,
        restoredState: snapshot,
        restoredComponents: restoredComponents,
      );

      return ClassroomStateRecoveryStatus.success;
    } catch (e) {
      _broadcastRecoveryEvent(
        ClassroomStateRecoveryStatus.persistenceError,
        errorMessage: 'Recovery failed: $e',
      );
      return ClassroomStateRecoveryStatus.persistenceError;
    }
  }

  /// Restore specific component of classroom state
  Future<bool> restoreComponent(String componentKey) async {
    try {
      if (!_initialized) await initialize();

      final stateJson = _prefs.getString(_stateKey);
      if (stateJson == null) return false;

      final parsed = jsonDecode(stateJson) as Map<String, dynamic>;
      final componentValue = parsed[componentKey];

      if (componentValue != null) {
        _inMemoryState[componentKey] = componentValue;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get recovered state (from memory or load)
  ClassroomStateSnapshot? getRecoveredState() {
    return _inMemoryState['restoredState'] as ClassroomStateSnapshot?;
  }

  /// Get specific component from recovered state
  T? getComponent<T>(String key) {
    return _inMemoryState[key] as T?;
  }

  /// Validate state structure
  bool isStateValid(ClassroomStateSnapshot? state) {
    if (state == null) return false;
    // Must have at least session ID and topic to be valid
    return state.sessionId != null && state.sessionId!.isNotEmpty;
  }

  /// Calculate checksum for validation
  int _calculateChecksum(ClassroomStateSnapshot state) {
    final data = jsonEncode({
      'sessionId': state.sessionId,
      'currentTopic': state.currentTopic,
      'currentChapter': state.currentChapter,
      'messageHistoryCount': state.messageHistory?.length ?? 0,
      'progressVersion': state.studentProgress?['version'] ?? 0,
    });
    return data.hashCode;
  }

  /// Clear persisted state
  Future<void> clearState() async {
    _inMemoryState.clear();
    _recoveryAttemptCount = 0;

    if (!_initialized) await initialize();

    await Future.wait([
      _prefs.remove(_stateKey),
      _prefs.remove(_timestampKey),
      _prefs.remove(_checksumKey),
    ]);
  }

  /// Broadcast recovery event
  void _broadcastRecoveryEvent(
    ClassroomStateRecoveryStatus status, {
    ClassroomStateSnapshot? restoredState,
    String? errorMessage,
    List<String>? restoredComponents,
  }) {
    _recoveryEvents.add(ClassroomStateRecoveryEvent(
      status: status,
      timestamp: DateTime.now(),
      restoredState: restoredState,
      errorMessage: errorMessage,
      restoredComponents: restoredComponents,
    ));
  }

  /// Stream of recovery events
  Stream<ClassroomStateRecoveryEvent> get recoveryEvents =>
      _recoveryEvents.stream;

  /// Get recovery metrics
  Map<String, dynamic> getMetrics() => {
    'recoveryAttemptCount': _recoveryAttemptCount,
    'hasRestoredState': _inMemoryState.containsKey('restoredState'),
    'lastCaptureTime': _inMemoryState['captureTime'],
    'lastRestoreTime': _inMemoryState['restoreTime'],
  };

  void dispose() {
    _recoveryEvents.close();
  }
}
