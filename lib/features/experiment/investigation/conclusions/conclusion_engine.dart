import '../analytics/investigation_analytics.dart';
import '../comparison/trend_detector.dart';
import '../models/experiment_trial.dart';
import '../models/trial_comparison.dart';

class ConclusionEngine {
  final InvestigationAnalytics analytics;
  final TrendDetector trendDetector;

  const ConclusionEngine({
    required this.analytics,
    this.trendDetector = const TrendDetector(),
  });

  String generate({
    required List<ExperimentTrial> trials,
    List<TrialComparison> comparisons = const [],
  }) {
    analytics.conclusionsGenerated++;
    if (trials.length < 2) {
      return 'Run at least two trials before drawing a conclusion.';
    }
    final numericSeries = _numericSeries(trials);
    if (numericSeries.isEmpty) {
      if (comparisons.isNotEmpty) {
        return 'Across the trials, ${comparisons.last.summary}';
      }
      return 'The trials were completed, but no numeric trend was detected.';
    }
    final primary = numericSeries.entries.first;
    final trend = trendDetector.detect(primary.value);
    return trendDetector.describe(_label(primary.key), trend);
  }

  Map<String, List<num>> _numericSeries(List<ExperimentTrial> trials) {
    final series = <String, List<num>>{};
    for (final trial in trials) {
      for (final entry in trial.parameterValues.entries) {
        final value = entry.value;
        if (value is num) {
          series.putIfAbsent(entry.key, () => <num>[]).add(value);
        }
      }
      for (final entry in trial.measurements.entries) {
        final value = entry.value;
        if (value is num) {
          series.putIfAbsent(entry.key, () => <num>[]).add(value);
        }
      }
    }
    series.removeWhere((_, values) => values.length < 2);
    return series;
  }

  String _label(String key) {
    return key.replaceAll(RegExp(r'^(var_|param_)'), '').replaceAll('_', ' ');
  }
}
