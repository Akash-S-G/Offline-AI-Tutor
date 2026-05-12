class DistributedMetricsService {
  int localInference = 0;
  int backendEscalations = 0;
  int streamFailures = 0;
  int syncFailures = 0;
  int offlineUses = 0;

  void recordLocal() => localInference++;
  void recordBackendEscalation() => backendEscalations++;
  void recordStreamFailure() => streamFailures++;
  void recordSyncFailure() => syncFailures++;
  void recordOfflineUse() => offlineUses++;

  Map<String, int> snapshot() => {
        'localInference': localInference,
        'backendEscalations': backendEscalations,
        'streamFailures': streamFailures,
        'syncFailures': syncFailures,
        'offlineUses': offlineUses,
      };
}
