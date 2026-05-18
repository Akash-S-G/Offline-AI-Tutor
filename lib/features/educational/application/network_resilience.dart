import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../config/app_environment.dart';
import 'sync_manager.dart';

/// Network state enumeration
enum NetworkState {
  online,
  offline,
  reconnecting,
  degraded,
}

/// Offline mode manager for handling disconnected state
class OfflineModeManager {
  static final OfflineModeManager _instance = OfflineModeManager._internal();

  factory OfflineModeManager() {
    return _instance;
  }

  OfflineModeManager._internal();

  NetworkState _currentState = NetworkState.online;
  final _stateController = StreamController<NetworkState>.broadcast();
  DateTime? _lastOnlineTime;

  NetworkState get currentState => _currentState;
  Stream<NetworkState> get stateStream => _stateController.stream;
  bool get isOffline => _currentState == NetworkState.offline;
  bool get isOnline => _currentState == NetworkState.online;

  /// Update network state
  void setNetworkState(NetworkState state) {
    if (_currentState != state) {
      AppEnvironment.log('RECOVERY', '[OfflineMode] State changed: ${_currentState.name} → ${state.name}');

      _currentState = state;
      _stateController.add(state);

      if (state == NetworkState.online) {
        _lastOnlineTime = DateTime.now();
        _triggerSyncOnReconnect();
      }
    }
  }

  /// Check if should go offline (based on backend availability)
  Future<bool> checkConnectivity() async {
    try {
      // TODO: Implement actual connectivity check
      // For now, return based on environment flag
      final offlineMode = dotenv.env['ENABLE_OFFLINE_PACKS']?.toLowerCase() == 'true';
      return !offlineMode;
    } catch (e) {
      AppEnvironment.log('RECOVERY', '[OfflineMode] Connectivity check failed: $e');
      setNetworkState(NetworkState.offline);
      return false;
    }
  }

  /// Attempt to reconnect
  Future<bool> attemptReconnect() async {
    try {
      AppEnvironment.log('RECOVERY', '[OfflineMode] Attempting reconnect');
      setNetworkState(NetworkState.reconnecting);

      final isConnected = await checkConnectivity();

      if (isConnected) {
        setNetworkState(NetworkState.online);
        return true;
      } else {
        setNetworkState(NetworkState.offline);
        return false;
      }
    } catch (e) {
      AppEnvironment.log('RECOVERY', '[OfflineMode] Reconnect failed: $e');
      setNetworkState(NetworkState.offline);
      return false;
    }
  }

  /// Get offline duration
  Duration? getOfflineDuration() {
    if (isOnline && _lastOnlineTime != null) {
      return DateTime.now().difference(_lastOnlineTime!);
    }
    return null;
  }

  void _triggerSyncOnReconnect() {
    if (dotenv.env['AUTO_SYNC_ON_RECONNECT']?.toLowerCase() == 'true') {
      AppEnvironment.log('RECOVERY', '[OfflineMode] Triggering auto-sync on reconnect');
      unawaited(
        SyncManager().checkForPackUpdates().then((updates) {
          AppEnvironment.log(
            'RECOVERY',
            '[OfflineMode] Reconnect sync check complete (${updates.length} updates)',
          );
        }).catchError((e) {
          AppEnvironment.log('RECOVERY', '[OfflineMode] Reconnect sync check failed: $e');
        }),
      );
    }
  }

  void dispose() {
    _stateController.close();
  }
}

/// Retry manager with exponential backoff
class RetryManager {
  static final RetryManager _instance = RetryManager._internal();

  factory RetryManager() {
    return _instance;
  }

  RetryManager._internal() {
    _maxRetries = int.tryParse(dotenv.env['MAX_RETRY_ATTEMPTS'] ?? '3') ?? 3;
    _baseDelay = int.tryParse(dotenv.env['RETRY_DELAY_SECONDS'] ?? '5') ?? 5;
    _backoffMultiplier =
        double.tryParse(dotenv.env['BACKOFF_MULTIPLIER'] ?? '2.0') ?? 2.0;
  }

  late int _maxRetries;
  late int _baseDelay;
  late double _backoffMultiplier;

  /// Execute operation with retry logic
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    String operationName = 'Operation',
  }) async {
    int attempt = 0;
    int delay = _baseDelay * 1000; // Convert to milliseconds

    while (attempt < _maxRetries) {
      try {
        AppEnvironment.log(
          'RECOVERY',
          '[RetryManager] Attempt ${attempt + 1}/$_maxRetries: $operationName',
        );

        return await operation().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Operation timed out'),
        );
      } on TimeoutException {
        AppEnvironment.log(
          'RECOVERY',
          '[RetryManager] Timeout on attempt ${attempt + 1}: $operationName',
        );
        attempt++;

        if (attempt >= _maxRetries) {
          rethrow;
        }

        await Future.delayed(Duration(milliseconds: delay));
        delay = (delay * _backoffMultiplier).toInt();
      } catch (e) {
        AppEnvironment.log(
          'RECOVERY',
          '[RetryManager] Error on attempt ${attempt + 1}: $operationName - $e',
        );
        attempt++;

        if (attempt >= _maxRetries) {
          rethrow;
        }

        await Future.delayed(Duration(milliseconds: delay));
        delay = (delay * _backoffMultiplier).toInt();
      }
    }

    throw Exception('Max retries exceeded for $operationName');
  }

  /// Get retry delay for attempt
  Duration getRetryDelay(int attemptNumber) {
    final delay = _baseDelay * (math.pow(_backoffMultiplier, attemptNumber)).toInt();
    return Duration(seconds: delay);
  }
}

/// Cache validator and management
class CacheValidator {
  static final CacheValidator _instance = CacheValidator._internal();

  factory CacheValidator() {
    return _instance;
  }

  CacheValidator._internal();

  final Map<String, CacheEntry> _cache = {};

  /// Cache time-to-live defaults
  static const defaultTTL = Duration(hours: 24);
  static const searchCacheTTL = Duration(hours: 6);
  static const packetCacheTTL = Duration(days: 30);

  /// Get cached value if valid
  T? getCachedValue<T>(String key) {
    final entry = _cache[key];

    if (entry == null) {
      AppEnvironment.log('RECOVERY', '[CacheValidator] Cache miss: $key');
      return null;
    }

    if (entry.isExpired) {
      AppEnvironment.log('RECOVERY', '[CacheValidator] Cache expired: $key');
      _cache.remove(key);
      return null;
    }

    AppEnvironment.log('RECOVERY', '[CacheValidator] Cache hit: $key');
    entry.lastAccessed = DateTime.now();
    return entry.value as T?;
  }

  /// Cache a value
  void cacheValue<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = CacheEntry(
      value: value,
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
      ttl: ttl ?? defaultTTL,
    );

    AppEnvironment.log('RECOVERY', '[CacheValidator] Cached: $key');
  }

  /// Invalidate cache entry
  void invalidate(String key) {
    _cache.remove(key);
    AppEnvironment.log('RECOVERY', '[CacheValidator] Invalidated: $key');
  }

  /// Invalidate all cache entries matching pattern
  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys.where((k) => regex.hasMatch(k)).toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    AppEnvironment.log(
      'RECOVERY',
      '[CacheValidator] Invalidated ${keysToRemove.length} entries matching: $pattern',
    );
  }

  /// Validate cache integrity
  bool validateCacheIntegrity(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final validEntries = _cache.values.where((e) => !e.isExpired).length;
    final expiredEntries = _cache.values.where((e) => e.isExpired).length;

    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'oldestEntry': _cache.values.isEmpty
          ? null
          : _cache.values
              .fold<DateTime>(_cache.values.first.createdAt,
                  (min, e) => e.createdAt.isBefore(min) ? e.createdAt : min)
              .toIso8601String(),
    };
  }

  /// Clear expired entries
  void clearExpired() {
    final keysToRemove =
        _cache.entries.where((e) => e.value.isExpired).map((e) => e.key).toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    AppEnvironment.log(
      'RECOVERY',
      '[CacheValidator] Cleared ${keysToRemove.length} expired entries',
    );
  }
}

/// Cache entry with TTL
class CacheEntry {
  final dynamic value;
  final DateTime createdAt;
  DateTime lastAccessed;
  final Duration ttl;

  CacheEntry({
    required this.value,
    required this.createdAt,
    required this.lastAccessed,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}

/// Network resilience coordinator
class NetworkResilienceCoordinator {
  static final NetworkResilienceCoordinator _instance =
      NetworkResilienceCoordinator._internal();

  factory NetworkResilienceCoordinator() {
    return _instance;
  }

  NetworkResilienceCoordinator._internal();

  final _offlineMode = OfflineModeManager();
  final _retryManager = RetryManager();
  final _cacheValidator = CacheValidator();

  OfflineModeManager get offlineMode => _offlineMode;
  RetryManager get retryManager => _retryManager;
  CacheValidator get cacheValidator => _cacheValidator;

  /// Execute operation with full resilience
  Future<T> executeWithResilience<T>(
    Future<T> Function() operation, {
    String operationName = 'Operation',
    T? Function()? fallback,
  }) async {
    try {
      // Check offline mode first
      if (_offlineMode.isOffline) {
        AppEnvironment.log(
          'RECOVERY',
          '[NetworkResilience] Offline mode - using fallback for: $operationName',
        );

        if (fallback != null) {
          final result = fallback();
          if (result != null) {
            return result;
          }
        }

        throw Exception('Offline and no fallback available');
      }

      // Execute with retry and timeout
      return await _retryManager.executeWithRetry(
        operation,
        operationName: operationName,
      );
    } catch (e) {
      AppEnvironment.log(
        'RECOVERY',
        '[NetworkResilience] Operation failed: $operationName - $e',
      );

      // Try fallback on failure
      if (fallback != null) {
        AppEnvironment.log(
          'RECOVERY',
          '[NetworkResilience] Executing fallback: $operationName',
        );
        final result = fallback();
        if (result != null) {
          return result;
        }
      }

      rethrow;
    }
  }

  /// Get system resilience status
  Future<Map<String, dynamic>> getResilienceStatus() async {
    final connectivity = await _offlineMode.checkConnectivity();

    return {
      'networkState': _offlineMode.currentState.name,
      'isOnline': connectivity,
      'offlineDuration': _offlineMode.getOfflineDuration()?.inSeconds,
      'cacheStats': _cacheValidator.getCacheStats(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Initialize resilience monitoring
  void startMonitoring({Duration checkInterval = const Duration(minutes: 5)}) {
    Timer.periodic(checkInterval, (_) async {
      try {
        final isOnline = await _offlineMode.checkConnectivity();
        _offlineMode.setNetworkState(
          isOnline ? NetworkState.online : NetworkState.offline,
        );

        _cacheValidator.clearExpired();
      } catch (e) {
        AppEnvironment.log('RECOVERY', '[NetworkResilience] Monitoring error: $e');
      }
    });

    AppEnvironment.log(
      'RECOVERY',
      '[NetworkResilience] Started monitoring with ${checkInterval.inSeconds}s interval',
    );
  }
}
