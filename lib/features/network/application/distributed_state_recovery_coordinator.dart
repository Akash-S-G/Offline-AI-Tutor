import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum StateRecoveryStatus {
  success,
  stateNotFound,
  stateInvalid,
  persistenceError,
  validationFailed,
}

/// Represents a state snapshot for recovery purposes
class StateRecoverySnapshot {
  final StateRecoveryStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? restoredState;
  final String? errorMessage;
  final List<String>? modifiedKeys;

  StateRecoverySnapshot({
    required this.status,
    required this.timestamp,
    this.restoredState,
    this.errorMessage,
    this.modifiedKeys,
  });
}

/// Enhanced distributed state recovery coordinator with persistent snapshots
class DistributedStateRecoveryCoordinator {
  static const String _statePrefix = 'dist_state_';
  static const String _timestampPrefix = 'dist_state_ts_';
  static const String _versionPrefix = 'dist_state_ver_';
  static const int _maxStateAge = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
  static const int _maxRecoveryAttempts = 3;

  final Map<String, dynamic> _inMemoryState = <String, dynamic>{};
  final Map<String, int> _recoveryAttempts = <String, int>{};
  final Map<String, int> _stateVersions = <String, int>{};
  final StreamController<StateRecoverySnapshot> _recoveryEvents =
      StreamController<StateRecoverySnapshot>.broadcast();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Save state persistently with versioning
  Future<void> save(String key, dynamic value) async {
    try {
      _inMemoryState[key] = value;
      
      if (!_initialized) await initialize();
      
      // Serialize value
      final serialized = jsonEncode(value);
      
      // Increment version
      final version = (_stateVersions[key] ?? 0) + 1;
      _stateVersions[key] = version;
      
      // Persist
      await Future.wait([
        _prefs.setString('$_statePrefix$key', serialized),
        _prefs.setInt('$_timestampPrefix$key', DateTime.now().millisecondsSinceEpoch),
        _prefs.setInt('$_versionPrefix$key', version),
      ]);
    } catch (e) {
      _broadcastRecoveryEvent(
        StateRecoveryStatus.persistenceError,
        errorMessage: 'Failed to save state: $e',
      );
    }
  }

  /// Load state from memory first, then persistence
  T? load<T>(String key) {
    if (_inMemoryState.containsKey(key)) {
      return _inMemoryState[key] as T?;
    }
    
    try {
      if (!_initialized) return null;
      
      final persisted = _prefs.getString('$_statePrefix$key');
      if (persisted == null) return null;
      
      // Check age
      final timestamp = _prefs.getInt('$_timestampPrefix$key') ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > _maxStateAge) return null;
      
      final value = jsonDecode(persisted) as T;
      _inMemoryState[key] = value; // Cache in memory
      return value;
    } catch (e) {
      return null;
    }
  }

  /// Validate state structure
  bool isStateValid(Map<String, dynamic>? state) {
    if (state == null || state.isEmpty) return false;
    
    // Verify essential structure
    return state.containsKey('version') && 
           state['version'] is int &&
           state.containsKey('timestamp');
  }

  /// Attempt to recover state by key with validation
  Future<StateRecoveryStatus> attemptRecovery(String key) async {
    try {
      if (!_initialized) await initialize();
      
      // Check recovery attempts
      final attempts = _recoveryAttempts[key] ?? 0;
      if (attempts >= _maxRecoveryAttempts) {
        _broadcastRecoveryEvent(
          StateRecoveryStatus.validationFailed,
          errorMessage: 'Max recovery attempts exceeded for key: $key',
          modifiedKeys: [key],
        );
        return StateRecoveryStatus.validationFailed;
      }
      _recoveryAttempts[key] = attempts + 1;
      
      // Try to load persisted state
      final persisted = _prefs.getString('$_statePrefix$key');
      if (persisted == null) {
        _broadcastRecoveryEvent(StateRecoveryStatus.stateNotFound);
        return StateRecoveryStatus.stateNotFound;
      }
      
      // Parse and validate
      final parsed = jsonDecode(persisted) as Map<String, dynamic>;
      if (!isStateValid(parsed)) {
        _broadcastRecoveryEvent(StateRecoveryStatus.stateInvalid);
        return StateRecoveryStatus.stateInvalid;
      }
      
      // Restore to in-memory
      _inMemoryState[key] = parsed;
      
      _broadcastRecoveryEvent(
        StateRecoveryStatus.success,
        restoredState: parsed,
        modifiedKeys: [key],
      );
      return StateRecoveryStatus.success;
    } catch (e) {
      _broadcastRecoveryEvent(
        StateRecoveryStatus.persistenceError,
        errorMessage: 'Recovery failed: $e',
      );
      return StateRecoveryStatus.persistenceError;
    }
  }

  /// Recover multiple states
  Future<Map<String, StateRecoveryStatus>> recoverMultiple(List<String> keys) async {
    final results = <String, StateRecoveryStatus>{};
    for (final key in keys) {
      results[key] = await attemptRecovery(key);
    }
    return results;
  }

  /// Get state diff (changes since last checkpoint)
  Map<String, dynamic> getStateDiff(String key) {
    try {
      if (!_initialized) return {};
      
      final current = _inMemoryState[key];
      final persisted = _prefs.getString('$_statePrefix$key');
      
      if (current == null || persisted == null) return {};
      
      final persistedData = jsonDecode(persisted);
      if (current == persistedData) return {};
      
      return {'changed': true, 'previous': persistedData, 'current': current};
    } catch (e) {
      return {};
    }
  }

  /// Clean up stale states (older than 24 hours)
  Future<int> cleanupStaleStates() async {
    if (!_initialized) await initialize();
    
    int cleaned = 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(_timestampPrefix)) continue;
      
      final keyName = key.substring(_timestampPrefix.length);
      final timestamp = _prefs.getInt(key) ?? 0;
      final age = now - timestamp;
      
      if (age > _maxStateAge) {
        await Future.wait([
          _prefs.remove('$_statePrefix$keyName'),
          _prefs.remove(key),
          _prefs.remove('$_versionPrefix$keyName'),
        ]);
        _inMemoryState.remove(keyName);
        cleaned++;
      }
    }
    
    return cleaned;
  }

  /// Clear specific state
  Future<void> clear(String key) async {
    _inMemoryState.remove(key);
    _recoveryAttempts.remove(key);
    
    if (!_initialized) await initialize();
    
    await Future.wait([
      _prefs.remove('$_statePrefix$key'),
      _prefs.remove('$_timestampPrefix$key'),
      _prefs.remove('$_versionPrefix$key'),
    ]);
  }

  /// Clear all states
  Future<void> clearAll() async {
    _inMemoryState.clear();
    _recoveryAttempts.clear();
    _stateVersions.clear();
    
    if (!_initialized) await initialize();
    
    final keys = _prefs.getKeys()
        .where((k) => k.startsWith(_statePrefix) || 
                      k.startsWith(_timestampPrefix) || 
                      k.startsWith(_versionPrefix))
        .toList();
    
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Get recovery events stream
  Stream<StateRecoverySnapshot> get recoveryEvents => _recoveryEvents.stream;

  /// Broadcast recovery event
  void _broadcastRecoveryEvent(
    StateRecoveryStatus status, {
    Map<String, dynamic>? restoredState,
    String? errorMessage,
    List<String>? modifiedKeys,
  }) {
    _recoveryEvents.add(StateRecoverySnapshot(
      status: status,
      timestamp: DateTime.now(),
      restoredState: restoredState,
      errorMessage: errorMessage,
      modifiedKeys: modifiedKeys,
    ));
  }

  /// Get recovery metrics
  Map<String, dynamic> getMetrics() => {
    'inMemoryStates': _inMemoryState.length,
    'recoveryAttempts': _recoveryAttempts,
    'stateVersions': _stateVersions,
  };

  void dispose() {
    _recoveryEvents.close();
  }
}
