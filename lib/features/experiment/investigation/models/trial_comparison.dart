import 'experiment_trial.dart';
import 'comparison_result.dart';

class TrialComparison {
  final ExperimentTrial first;
  final ExperimentTrial second;
  final Map<String, dynamic> differences;
  final List<ComparisonResult> results;
  final String summary;

  const TrialComparison({
    required this.first,
    required this.second,
    required this.differences,
    this.results = const [],
    required this.summary,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstTrialId': first.trialId,
      'secondTrialId': second.trialId,
      'differences': differences,
      'results': results.map((result) => result.toJson()).toList(),
      'summary': summary,
    };
  }
}
