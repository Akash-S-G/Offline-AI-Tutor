import '../analytics/investigation_analytics.dart';
import 'conclusion_engine.dart';
import '../comparison/trial_comparator.dart';
import '../models/experiment_trial.dart';

class ConclusionGenerator {
  final InvestigationAnalytics analytics;

  const ConclusionGenerator({required this.analytics});

  String generate(List<ExperimentTrial> trials) {
    if (trials.length < 2) {
      analytics.conclusionsGenerated++;
      return 'Run at least two trials to support a conclusion.';
    }
    final comparison = TrialComparator(
      analytics: analytics,
    ).compare(trials[trials.length - 2], trials.last);
    return ConclusionEngine(
      analytics: analytics,
    ).generate(trials: trials, comparisons: [comparison]);
  }
}
