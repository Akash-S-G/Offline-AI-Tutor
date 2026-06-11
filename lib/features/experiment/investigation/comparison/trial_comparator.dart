import '../analytics/investigation_analytics.dart';
import '../models/comparison_result.dart';
import '../models/experiment_trial.dart';
import '../models/trial_comparison.dart';

class TrialComparator {
  final InvestigationAnalytics analytics;

  const TrialComparator({required this.analytics});

  TrialComparison compare(ExperimentTrial first, ExperimentTrial second) {
    final differences = <String, dynamic>{};
    final results = <ComparisonResult>[];
    final keys = {
      ...first.parameterValues.keys,
      ...second.parameterValues.keys,
      ...first.measurements.keys,
      ...second.measurements.keys,
    };
    for (final key in keys) {
      final a = first.parameterValues[key] ?? first.measurements[key];
      final b = second.parameterValues[key] ?? second.measurements[key];
      if (a is num && b is num) {
        final difference = b - a;
        differences[key] = difference;
        results.add(
          ComparisonResult(
            parameter: _label(key),
            trialA: a,
            trialB: b,
            difference: difference,
          ),
        );
      } else if (a != b) {
        final difference = {'from': a, 'to': b};
        differences[key] = difference;
        results.add(
          ComparisonResult(
            parameter: _label(key),
            trialA: a,
            trialB: b,
            difference: difference,
          ),
        );
      }
    }
    analytics.comparisonsGenerated++;
    return TrialComparison(
      first: first,
      second: second,
      differences: differences,
      results: results,
      summary: _summary(first, second, differences),
    );
  }

  String _summary(
    ExperimentTrial first,
    ExperimentTrial second,
    Map<String, dynamic> differences,
  ) {
    if (differences.isEmpty) {
      return 'Trial ${second.trialNumber} matched Trial ${first.trialNumber}.';
    }
    final parts = differences.entries
        .map((entry) {
          final value = entry.value;
          if (value is num) {
            if (value > 0) return '${_label(entry.key)} increased';
            if (value < 0) return '${_label(entry.key)} decreased';
            return '${_label(entry.key)} stayed the same';
          }
          return '${_label(entry.key)} changed';
        })
        .toList(growable: false);
    return '${parts.join(', ')}.';
  }

  String _label(String key) {
    return key.replaceAll(RegExp(r'^(var_|param_)'), '').replaceAll('_', ' ');
  }
}
