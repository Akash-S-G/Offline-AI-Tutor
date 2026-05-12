class ClassroomMetricsCollector {
  int offlineMinutes = 0;
  int backendFallbackFrequency = 0;

  void recordOfflineMinute() => offlineMinutes++;
  void recordBackendFallback() => backendFallbackFrequency++;
}
