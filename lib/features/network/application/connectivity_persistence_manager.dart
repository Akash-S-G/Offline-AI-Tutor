import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ConnectivityState {
  online,
  offline,
  weakSignal,
  reconnecting,
}

/// Records a single connectivity event for historical analysis
class ConnectivityEvent {
  final ConnectivityState state;
  final DateTime timestamp;
  final String? reason;
  final Duration? duration;

  ConnectivityEvent({
    required this.state,
    required this.timestamp,
    this.reason,
    this.duration,
  });

  Map<String, dynamic> toJson() => {
    'state': state.toString().split('.').last,
    'timestamp': timestamp.toIso8601String(),
    'reason': reason,
    'duration': duration?.inSeconds,
  };

  factory ConnectivityEvent.fromJson(Map<String, dynamic> json) {
    final stateStr = json['state'] as String?;
    final state = ConnectivityState.values.firstWhere(
      (s) => s.toString().split('.').last == stateStr,
      orElse: () => ConnectivityState.online,
    );
    
    return ConnectivityEvent(
      state: state,
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      reason: json['reason'] as String?,
      duration: json['duration'] != null ? Duration(seconds: json['duration'] as int) : null,
    );
  }
}

/// Tracks connectivity state changes with persistence for recovery analysis
class ConnectivityPersistenceManager {
  static const String _currentStateKey = 'conn_current_state';
  static const String _historyKey = 'conn_history';
  static const String _lastTransitionKey = 'conn_last_transition';
  static const int _maxHistorySize = 100; // Keep last 100 events
  static const int _historyRetentionMs = 7 * 24 * 60 * 60 * 1000; // 7 days

  final Map<String, dynamic> _inMemoryState = <String, dynamic>{};
  final List<ConnectivityEvent> _eventHistory = <ConnectivityEvent>[];
  final StreamController<ConnectivityEvent> _stateChanges =
      StreamController<ConnectivityEvent>.broadcast();

  late SharedPreferences _prefs;
  bool _initialized = false;
  ConnectivityState _currentState = ConnectivityState.online;
  DateTime? _lastStateChangeTime;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    // Load persisted state
    final savedState = _prefs.getString(_currentStateKey);
    if (savedState != null) {
      _currentState = ConnectivityState.values.firstWhere(
        (s) => s.toString().split('.').last == savedState,
        orElse: () => ConnectivityState.online,
      );
    }
    
    // Load history
    final historyJson = _prefs.getString(_historyKey);
    if (historyJson != null) {
      try {
        final List<dynamic> parsed = jsonDecode(historyJson);
        _eventHistory.addAll(
          parsed
              .map((e) => ConnectivityEvent.fromJson(e as Map<String, dynamic>))
              .toList()
        );
      } catch (e) {
        // Ignore corrupted history
      }
    }
    
    _initialized = true;
  }

  /// Record a connectivity state change with optional reason
  Future<void> recordStateChange(
    ConnectivityState newState, {
    String? reason,
  }) async {
    if (!_initialized) await initialize();
    
    final duration = _lastStateChangeTime != null
        ? DateTime.now().difference(_lastStateChangeTime!)
        : null;

    // Create event
    final event = ConnectivityEvent(
      state: newState,
      timestamp: DateTime.now(),
      reason: reason,
      duration: duration,
    );

    // Update current state
    _currentState = newState;
    _lastStateChangeTime = DateTime.now();

    // Add to history
    _eventHistory.add(event);
    
    // Maintain max history size
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeAt(0);
    }

    // Persist state
    await Future.wait([
      _prefs.setString(
        _currentStateKey,
        newState.toString().split('.').last,
      ),
      _persistHistory(),
      _prefs.setInt(_lastTransitionKey, DateTime.now().millisecondsSinceEpoch),
    ]);

    // Broadcast event
    _stateChanges.add(event);
  }

  /// Persist connectivity history
  Future<void> _persistHistory() async {
    try {
      final json = jsonEncode(_eventHistory.map((e) => e.toJson()).toList());
      await _prefs.setString(_historyKey, json);
    } catch (e) {
      // Ignore serialization errors
    }
  }

  /// Get current connectivity state
  ConnectivityState getCurrentState() => _currentState;

  /// Get event history
  List<ConnectivityEvent> getEventHistory({int limit = 50}) {
    return _eventHistory.length <= limit
        ? List.from(_eventHistory)
        : _eventHistory.sublist(_eventHistory.length - limit);
  }

  /// Analyze connectivity patterns
  Map<String, dynamic> analyzePatterns() {
    if (_eventHistory.isEmpty) return {};

    final offlineDurations = <Duration>[];
    final transitions = <String, int>{};

    for (final event in _eventHistory) {
      if (event.state == ConnectivityState.offline && event.duration != null) {
        offlineDurations.add(event.duration!);
      }
    }

    // Count transitions
    for (int i = 0; i < _eventHistory.length - 1; i++) {
      final from = _eventHistory[i].state.toString().split('.').last;
      final to = _eventHistory[i + 1].state.toString().split('.').last;
      final key = '$from -> $to';
      transitions[key] = (transitions[key] ?? 0) + 1;
    }

    final avgOfflineDuration = offlineDurations.isEmpty
        ? 0
        : offlineDurations
            .fold<int>(0, (sum, d) => sum + d.inSeconds) ~/
            offlineDurations.length;

    return {
      'totalEvents': _eventHistory.length,
      'totalOfflineEvents': _eventHistory
          .where((e) => e.state == ConnectivityState.offline)
          .length,
      'averageOfflineDuration': avgOfflineDuration,
      'longestOfflineDuration': offlineDurations.isEmpty
          ? 0
          : offlineDurations.reduce((a, b) => a.compareTo(b) > 0 ? a : b).inSeconds,
      'transitions': transitions,
      'currentState': _currentState.toString().split('.').last,
    };
  }

  /// Get connectivity recovery recommendations based on history
  List<String> getRecoveryRecommendations() {
    final patterns = analyzePatterns();
    final recommendations = <String>[];

    final totalOfflineEvents = patterns['totalOfflineEvents'] ?? 0;
    final totalEvents = patterns['totalEvents'] ?? 0;

    if (totalEvents == 0) return recommendations;

    final offlinePercentage = (totalOfflineEvents / totalEvents * 100).toInt();
    if (offlinePercentage > 30) {
      recommendations.add('High offline rate ($offlinePercentage%). Check network stability.');
    }

    final avgDuration = patterns['averageOfflineDuration'] ?? 0;
    if (avgDuration > 60) {
      recommendations.add('Long average offline duration ($avgDuration s). May need enhanced recovery.');
    }

    final transitions = patterns['transitions'] as Map<String, dynamic>? ?? {};
    if (transitions.containsKey('offline -> reconnecting')) {
      recommendations.add('Device attempts reconnection. Consider faster recovery strategies.');
    }

    return recommendations;
  }

  /// Clean up old events (older than 7 days)
  Future<int> cleanupOldEvents() async {
    if (!_initialized) await initialize();

    final cutoffTime = DateTime.now()
        .subtract(Duration(milliseconds: _historyRetentionMs));
    final initialLength = _eventHistory.length;

    _eventHistory.removeWhere((e) => e.timestamp.isBefore(cutoffTime));

    if (_eventHistory.length != initialLength) {
      await _persistHistory();
    }

    return initialLength - _eventHistory.length;
  }

  /// Stream of connectivity state changes
  Stream<ConnectivityEvent> get stateChanges => _stateChanges.stream;

  /// Get current metrics
  Map<String, dynamic> getMetrics() => {
    'currentState': _currentState.toString().split('.').last,
    'historySize': _eventHistory.length,
    'lastTransition': _lastStateChangeTime?.toIso8601String(),
  };

  void dispose() {
    _stateChanges.close();
  }
}
