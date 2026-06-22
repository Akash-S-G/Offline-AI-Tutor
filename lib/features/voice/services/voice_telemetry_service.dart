/// Telemetry collector for voice pipeline performance metrics.
///
/// Tracks latencies and failure counts for monitoring
/// against performance targets:
/// - Voice recording start: < 100ms
/// - WebSocket connect: < 500ms
/// - Partial transcript arrival: < 500ms
/// - Tutor response start: < 1000ms
/// - Audio playback start: < 200ms
class VoiceTelemetryService {
  final List<TelemetryEvent> _events = [];

  /// Record a timestamped metric.
  void record(TelemetryMetric metric, double valueMs) {
    _events.add(TelemetryEvent(
      metric: metric,
      valueMs: valueMs,
      timestamp: DateTime.now(),
    ));
  }

  /// Increment a counter metric (e.g. playback_failures).
  void increment(TelemetryMetric metric) {
    record(metric, 1.0);
  }

  /// Get the average value for a metric.
  double average(TelemetryMetric metric) {
    final matching = _events.where((e) => e.metric == metric);
    if (matching.isEmpty) return 0.0;
    return matching.map((e) => e.valueMs).reduce((a, b) => a + b) /
        matching.length;
  }

  /// Get the total count/sum for a counter metric.
  double total(TelemetryMetric metric) {
    return _events
        .where((e) => e.metric == metric)
        .map((e) => e.valueMs)
        .fold(0.0, (a, b) => a + b);
  }

  /// Get the last N events for a metric.
  List<TelemetryEvent> recent(TelemetryMetric metric, {int count = 10}) {
    return _events.where((e) => e.metric == metric).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Whether a metric exceeds its performance target.
  bool exceedsTarget(TelemetryMetric metric) {
    final avg = average(metric);
    return avg > metric.targetMs;
  }

  /// Get a summary of all tracked metrics.
  Map<TelemetryMetric, double> get summary {
    final result = <TelemetryMetric, double>{};
    for (final metric in TelemetryMetric.values) {
      final avg = average(metric);
      if (avg > 0) result[metric] = avg;
    }
    return result;
  }

  /// Clear all recorded events.
  void clear() => _events.clear();
}

/// Tracked performance metrics.
enum TelemetryMetric {
  connectionTime(targetMs: 500),
  recordingDuration(targetMs: double.infinity),
  responseLatency(targetMs: 1000),
  audioGenerationLatency(targetMs: 1000),
  playbackFailures(targetMs: double.infinity);

  const TelemetryMetric({required this.targetMs});

  /// Maximum acceptable value in milliseconds.
  final double targetMs;
}

/// A single telemetry measurement.
class TelemetryEvent {
  const TelemetryEvent({
    required this.metric,
    required this.valueMs,
    required this.timestamp,
  });

  final TelemetryMetric metric;
  final double valueMs;
  final DateTime timestamp;
}
