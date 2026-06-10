class BarChartState {
  final List<String> labels;
  final List<double> values;
  final double min;
  final double max;
  final DateTime? updatedAt;

  const BarChartState({
    required this.labels,
    required this.values,
    required this.min,
    required this.max,
    required this.updatedAt,
  });

  const BarChartState.empty()
    : labels = const [],
      values = const [],
      min = 0,
      max = 0,
      updatedAt = null;

  int get barCount => values.length;

  Map<String, dynamic> toObjectState() {
    return {
      'labels': labels,
      'values': values,
      'min': min,
      'max': max,
      'barCount': barCount,
    };
  }
}
