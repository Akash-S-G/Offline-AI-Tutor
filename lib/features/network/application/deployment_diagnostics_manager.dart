import 'dart:async';

enum DeploymentReadinessStatus {
  ready,
  backendNotReady,
  classroomNotReady,
  distributionNotReady,
  syncNotReady,
  notValidated,
}

class DeploymentDiagnosticsSnapshot {
  const DeploymentDiagnosticsSnapshot({
    required this.status,
    required this.timestamp,
    required this.backendReady,
    required this.classroomReady,
    required this.distributionReady,
    required this.syncReady,
    this.readinessPercent = 0,
    this.errorMessages = const [],
  });

  final DeploymentReadinessStatus status;
  final DateTime timestamp;
  final bool backendReady;
  final bool classroomReady;
  final bool distributionReady;
  final bool syncReady;
  final double readinessPercent;
  final List<String> errorMessages;

  bool get isFullyReady =>
      backendReady && classroomReady && distributionReady && syncReady;
}

class ClassroomStartupValidator {
  const ClassroomStartupValidator();

  bool isReady({
    required bool backendReady,
    required bool classroomReady,
    required bool distributionReady,
    required bool syncReady,
  }) {
    return backendReady && classroomReady && distributionReady && syncReady;
  }
}

class DeploymentDiagnosticsCoordinator {
  DeploymentDiagnosticsCoordinator()
      : _diagnosticsStream =
            StreamController<DeploymentDiagnosticsSnapshot>.broadcast();

  final StreamController<DeploymentDiagnosticsSnapshot> _diagnosticsStream;
  DeploymentDiagnosticsSnapshot _currentStatus = DeploymentDiagnosticsSnapshot(
    status: DeploymentReadinessStatus.notValidated,
    timestamp: DateTime.now(),
    backendReady: false,
    classroomReady: false,
    distributionReady: false,
    syncReady: false,
  );

  Stream<DeploymentDiagnosticsSnapshot> get diagnostics => _diagnosticsStream.stream;

  DeploymentDiagnosticsSnapshot get currentStatus => _currentStatus;

  Future<void> validateDeployment({
    required bool backendReady,
    required bool classroomReady,
    required bool distributionReady,
    required bool syncReady,
  }) async {
    final errors = <String>[];

    if (!backendReady) errors.add('Backend services not ready');
    if (!classroomReady) errors.add('Classroom coordination not ready');
    if (!distributionReady) errors.add('Distribution layer not ready');
    if (!syncReady) errors.add('Synchronization not ready');

    final readyCount = [backendReady, classroomReady, distributionReady, syncReady]
        .where((b) => b)
        .length;
    final readinessPercent = (readyCount / 4) * 100;

    final status = backendReady && classroomReady && distributionReady && syncReady
        ? DeploymentReadinessStatus.ready
        : backendReady
            ? classroomReady
                ? distributionReady ? DeploymentReadinessStatus.syncNotReady : DeploymentReadinessStatus.distributionNotReady
                : DeploymentReadinessStatus.classroomNotReady
            : DeploymentReadinessStatus.backendNotReady;

    _currentStatus = DeploymentDiagnosticsSnapshot(
      status: status,
      timestamp: DateTime.now(),
      backendReady: backendReady,
      classroomReady: classroomReady,
      distributionReady: distributionReady,
      syncReady: syncReady,
      readinessPercent: readinessPercent,
      errorMessages: errors,
    );

    _diagnosticsStream.add(_currentStatus);
  }

  String summarize() {
    return 'backend=${_currentStatus.backendReady} '
        'classroom=${_currentStatus.classroomReady} '
        'distribution=${_currentStatus.distributionReady} '
        'sync=${_currentStatus.syncReady} '
        'readiness=${_currentStatus.readinessPercent.toStringAsFixed(1)}%';
  }

  void close() {
    _diagnosticsStream.close();
  }
}

class RuntimeHealthMonitor {
  RuntimeHealthMonitor({
    this.checkIntervalSeconds = 10,
  })  : _healthStream = StreamController<Map<String, dynamic>>.broadcast();

  final int checkIntervalSeconds;
  final StreamController<Map<String, dynamic>> _healthStream;
  Timer? _monitorTimer;

  int checks = 0;
  int failures = 0;
  bool healthy = true;
  DateTime? lastCheck;

  Stream<Map<String, dynamic>> get healthEvents => _healthStream.stream;

  void recordCheck({required bool ok, String? reason}) {
    checks++;
    if (!ok) {
      failures++;
      healthy = false;
    }
    lastCheck = DateTime.now();

    _healthStream.add({
      'ok': ok,
      'checks': checks,
      'failures': failures,
      'healthy': healthy,
      'reason': reason,
      'timestamp': lastCheck!.toIso8601String(),
    });
  }

  void startMonitoring() {
    _monitorTimer = Timer.periodic(
      Duration(seconds: checkIntervalSeconds),
      (_) => recordCheck(ok: true, reason: 'Periodic health check'),
    );
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  double getHealthPercent() {
    if (checks == 0) return 100;
    return ((checks - failures) / checks) * 100;
  }

  Map<String, dynamic> getStatus() {
    return {
      'healthy': healthy,
      'checks': checks,
      'failures': failures,
      'healthPercent': getHealthPercent(),
      'lastCheck': lastCheck?.toIso8601String(),
    };
  }

  void close() {
    stopMonitoring();
    _healthStream.close();
  }
}
