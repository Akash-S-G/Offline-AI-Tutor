class RecoveryDiagnosticsManager {
  int reconnectFrequency = 0;
  int interruptedTransfers = 0;
  int syncRecoveryFailures = 0;

  void recordReconnect() => reconnectFrequency++;
  void recordInterruptedTransfer() => interruptedTransfers++;
  void recordSyncRecoveryFailure() => syncRecoveryFailures++;
}
