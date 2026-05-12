class PersistentSyncRecoveryManager {
  final List<Map<String, dynamic>> _failedOperations = <Map<String, dynamic>>[];

  void recordFailure(Map<String, dynamic> operation) {
    _failedOperations.add(Map<String, dynamic>.from(operation));
  }

  List<Map<String, dynamic>> drainFailures() {
    final items = List<Map<String, dynamic>>.from(_failedOperations);
    _failedOperations.clear();
    return items;
  }
}
