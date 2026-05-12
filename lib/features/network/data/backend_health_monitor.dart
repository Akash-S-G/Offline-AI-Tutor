import 'dart:async';

import 'backend_api_service.dart';

/// Health status of the backend.
enum BackendHealthStatus {
  /// Backend is reachable and responding
  healthy,

  /// Backend is reachable but slow
  degraded,

  /// Backend is unreachable
  unavailable,

  /// Health check not yet performed
  unknown,
}

/// Detailed health information.
class BackendHealthInfo {
  const BackendHealthInfo({
    required this.status,
    required this.timestamp,
    this.responseTimeMs,
    this.errorMessage,
    this.uptime,
    this.consecutiveFailures = 0,
  });

  /// Current health status
  final BackendHealthStatus status;

  /// When this check was performed
  final DateTime timestamp;

  /// Response time in milliseconds (if available)
  final int? responseTimeMs;

  /// Error message (if any)
  final String? errorMessage;

  /// Backend uptime (if available)
  final Duration? uptime;

  /// Number of consecutive failures
  final int consecutiveFailures;

  /// Whether backend is healthy
  bool get isHealthy => status == BackendHealthStatus.healthy;

  /// Whether backend is available (healthy or degraded)
  bool get isAvailable =>
      status == BackendHealthStatus.healthy ||
      status == BackendHealthStatus.degraded;

  factory BackendHealthInfo.unknown() {
    return BackendHealthInfo(
      status: BackendHealthStatus.unknown,
      timestamp: DateTime.now(),
    );
  }

  factory BackendHealthInfo.healthy({
    int? responseTimeMs,
    Duration? uptime,
  }) {
    return BackendHealthInfo(
      status: BackendHealthStatus.healthy,
      timestamp: DateTime.now(),
      responseTimeMs: responseTimeMs,
      uptime: uptime,
    );
  }

  factory BackendHealthInfo.degraded({
    required int responseTimeMs,
    Duration? uptime,
  }) {
    return BackendHealthInfo(
      status: BackendHealthStatus.degraded,
      timestamp: DateTime.now(),
      responseTimeMs: responseTimeMs,
      uptime: uptime,
    );
  }

  factory BackendHealthInfo.unavailable({
    required String errorMessage,
    int consecutiveFailures = 1,
  }) {
    return BackendHealthInfo(
      status: BackendHealthStatus.unavailable,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
      consecutiveFailures: consecutiveFailures,
    );
  }

  @override
  String toString() =>
      'BackendHealthInfo(status=$status, responseTimeMs=$responseTimeMs, errors=$consecutiveFailures)';
}

/// Monitors backend health continuously.
class BackendHealthMonitor {
  BackendHealthMonitor({
    required BackendApiService backendService,
    this.checkIntervalSeconds = 60,
    this.responseTimeThresholdMs = 200,
    this.consecutiveFailuresThreshold = 3,
  })  : _backendService = backendService,
        _healthStream = StreamController<BackendHealthInfo>.broadcast();

  final BackendApiService _backendService;
  final int checkIntervalSeconds;
  final int responseTimeThresholdMs;
  final int consecutiveFailuresThreshold;
  final StreamController<BackendHealthInfo> _healthStream;

  Timer? _timer;
  BackendHealthInfo _currentHealth = BackendHealthInfo.unknown();
  int _consecutiveFailures = 0;

  /// Stream of health updates
  Stream<BackendHealthInfo> get healthUpdates => _healthStream.stream;

  /// Get current health status
  BackendHealthInfo get currentHealth => _currentHealth;

  /// Start health monitoring
  Future<void> start() async {
    // Initial check
    await _performHealthCheck();

    // Periodic checks
    _timer = Timer.periodic(
      Duration(seconds: checkIntervalSeconds),
      (_) => _performHealthCheck(),
    );
  }

  /// Stop health monitoring
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Force immediate health check
  Future<void> check() async {
    await _performHealthCheck();
  }

  /// Perform a health check
  Future<void> _performHealthCheck() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await _backendService.healthCheck();
      stopwatch.stop();

      if (response.isSuccess) {
        _consecutiveFailures = 0;

        // Determine if healthy or degraded
        final responseTime = stopwatch.elapsedMilliseconds;
        BackendHealthInfo health;

        if (responseTime > responseTimeThresholdMs) {
          health = BackendHealthInfo.degraded(
            responseTimeMs: responseTime,
          );
        } else {
          health = BackendHealthInfo.healthy(
            responseTimeMs: responseTime,
          );
        }

        _currentHealth = health;
        _healthStream.add(health);
      } else {
        _consecutiveFailures++;

        final health = BackendHealthInfo.unavailable(
          errorMessage: response.message ?? 'Health check failed',
          consecutiveFailures: _consecutiveFailures,
        );

        _currentHealth = health;
        _healthStream.add(health);
      }
    } catch (error) {
      _consecutiveFailures++;

      final health = BackendHealthInfo.unavailable(
        errorMessage: error.toString(),
        consecutiveFailures: _consecutiveFailures,
      );

      _currentHealth = health;
      _healthStream.add(health);
    }
  }

  /// Close the monitor
  void close() {
    stop();
    _healthStream.close();
  }
}
