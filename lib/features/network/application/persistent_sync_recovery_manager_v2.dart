import 'dart:async';

enum SyncRecoveryStatus {
  recovered,
  noInterruption,
  retryScheduled,
  maxRetriesExceeded,
  operationNotFound,
}

class InterruptedSyncOperation {
  const InterruptedSyncOperation({
    required this.id,
    required this.operation,
    required this.failedAt,
    required this.lastAttemptAt,
    this.attemptCount = 1,
    this.error,
  });

  final String id;
  final Map<String, dynamic> operation;
  final DateTime failedAt;
  final DateTime lastAttemptAt;
  final int attemptCount;
  final String? error;

  bool get isRetryable => attemptCount < 3;
}

class SyncRecoverySnapshot {
  const SyncRecoverySnapshot({
    required this.status,
    required this.timestamp,
    this.recoveredOperations = 0,
    this.pendingRetries = 0,
    this.failedOperations = 0,
  });

  final SyncRecoveryStatus status;
  final DateTime timestamp;
  final int recoveredOperations;
  final int pendingRetries;
  final int failedOperations;
}

class PersistentSyncRecoveryManager {
  PersistentSyncRecoveryManager({
    this.maxRetryAttempts = 3,
    this.retryDelaySeconds = 30,
  });

  final int maxRetryAttempts;
  final int retryDelaySeconds;
  final Map<String, InterruptedSyncOperation> _interruptedOps =
      <String, InterruptedSyncOperation>{};
  final List<Map<String, dynamic>> _failedOps = <Map<String, dynamic>>[];
  final StreamController<SyncRecoverySnapshot> _recoveryStream =
      StreamController<SyncRecoverySnapshot>.broadcast();

  Stream<SyncRecoverySnapshot> get recoveryEvents => _recoveryStream.stream;

  void recordInterruption(
    String operationId,
    Map<String, dynamic> operation, {
    String? error,
  }) {
    final existing = _interruptedOps[operationId];
    final attemptCount = (existing?.attemptCount ?? 0) + 1;

    _interruptedOps[operationId] = InterruptedSyncOperation(
      id: operationId,
      operation: Map<String, dynamic>.from(operation),
      failedAt: existing?.failedAt ?? DateTime.now(),
      lastAttemptAt: DateTime.now(),
      attemptCount: attemptCount,
      error: error,
    );

    _publishSnapshot();
  }

  Future<SyncRecoveryStatus> attemptRecovery(String operationId) async {
    final op = _interruptedOps[operationId];
    if (op == null) {
      return SyncRecoveryStatus.operationNotFound;
    }

    if (!op.isRetryable) {
      _failedOps.add({
        'operationId': operationId,
        'operation': op.operation,
        'finalError': op.error,
        'failedAfterAttempts': op.attemptCount,
      });
      _interruptedOps.remove(operationId);
      return SyncRecoveryStatus.maxRetriesExceeded;
    }

    // Schedule retry
    return SyncRecoveryStatus.retryScheduled;
  }

  Future<void> retryAllInterrupted() async {
    final toRetry = List<String>.from(_interruptedOps.keys);
    for (final opId in toRetry) {
      await attemptRecovery(opId);
    }
  }

  List<InterruptedSyncOperation> getPendingRetries() {
    return _interruptedOps.values
        .where((op) => op.isRetryable)
        .toList();
  }

  List<Map<String, dynamic>> getFailedOperations() {
    return List<Map<String, dynamic>>.from(_failedOps);
  }

  void clearOperation(String operationId) {
    _interruptedOps.remove(operationId);
    _publishSnapshot();
  }

  void clearAll() {
    _interruptedOps.clear();
    _failedOps.clear();
    _publishSnapshot();
  }

  void _publishSnapshot() {
    _recoveryStream.add(
      SyncRecoverySnapshot(
        status: _interruptedOps.isEmpty
            ? SyncRecoveryStatus.noInterruption
            : SyncRecoveryStatus.retryScheduled,
        timestamp: DateTime.now(),
        recoveredOperations: 0,
        pendingRetries: _interruptedOps.length,
        failedOperations: _failedOps.length,
      ),
    );
  }

  void close() {
    _recoveryStream.close();
  }
}
