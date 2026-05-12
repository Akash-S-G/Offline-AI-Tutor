/// Simple routing metrics tracker.
class RoutingMetricsTracker {
  int localCount = 0;
  int backendCount = 0;
  int escalations = 0;
  int failures = 0;

  void recordLocal() => localCount++;
  void recordBackend() => backendCount++;
  void recordEscalation() => escalations++;
  void recordFailure() => failures++;

  Map<String, dynamic> snapshot() {
    return {
      'local': localCount,
      'backend': backendCount,
      'escalations': escalations,
      'failures': failures,
    };
  }
}
