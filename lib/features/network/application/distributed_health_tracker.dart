class DistributedHealthTracker {
  int connectivityEvents = 0;
  int syncEvents = 0;

  void recordConnectivity() => connectivityEvents++;
  void recordSync() => syncEvents++;
}
