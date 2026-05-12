class SyncDiagnosticsManager {
  int syncRuns = 0;
  int resumptions = 0;
  int interruptions = 0;

  void recordRun() => syncRuns++;
  void recordResumption() => resumptions++;
  void recordInterruption() => interruptions++;

  Map<String, int> snapshot() => {
        'syncRuns': syncRuns,
        'resumptions': resumptions,
        'interruptions': interruptions,
      };
}
