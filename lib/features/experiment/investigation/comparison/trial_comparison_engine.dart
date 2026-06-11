import '../analytics/investigation_analytics.dart';
import '../models/experiment_trial.dart';
import '../models/trial_comparison.dart';
import 'trial_comparator.dart';

class TrialComparisonEngine {
  final InvestigationAnalytics analytics;
  late final TrialComparator _comparator;

  TrialComparisonEngine({required this.analytics}) {
    _comparator = TrialComparator(analytics: analytics);
  }

  TrialComparison compare(ExperimentTrial first, ExperimentTrial second) {
    return _comparator.compare(first, second);
  }

  List<TrialComparison> compareSeries(List<ExperimentTrial> trials) {
    if (trials.length < 2) return const [];
    final comparisons = <TrialComparison>[];
    for (var i = 1; i < trials.length; i++) {
      comparisons.add(compare(trials[i - 1], trials[i]));
    }
    return comparisons;
  }
}
