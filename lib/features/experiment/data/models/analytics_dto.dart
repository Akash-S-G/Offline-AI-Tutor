class AnalyticsDto {
  final int totalRuns;
  final int totalEvents;
  final double averageDurationMs;

  AnalyticsDto({
    required this.totalRuns,
    required this.totalEvents,
    required this.averageDurationMs,
  });

  factory AnalyticsDto.fromJson(Map<String, dynamic> json) {
    return AnalyticsDto(
      totalRuns: json['total_runs'] ?? 0,
      totalEvents: json['total_events'] ?? 0,
      averageDurationMs: (json['average_duration_ms'] ?? 0).toDouble(),
    );
  }
}
