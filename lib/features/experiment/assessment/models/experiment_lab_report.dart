import '../../guided_runtime/models/experiment_mission.dart';
import '../../investigation/models/experiment_trial.dart';
import '../../investigation/models/trial_comparison.dart';
import 'assessment_result.dart';
import 'learning_outcome_result.dart';

class ExperimentLabReport {
  final String id;
  final String title;
  final DateTime generatedAt;
  final ExperimentMission? mission;
  final List<ExperimentTrial> trials;
  final List<Map<String, dynamic>> observations;
  final List<TrialComparison> comparisons;
  final String conclusion;
  final AssessmentResult? assessmentResult;
  final List<LearningOutcomeResult> learningOutcomes;

  const ExperimentLabReport({
    required this.id,
    required this.title,
    required this.generatedAt,
    this.mission,
    this.trials = const [],
    this.observations = const [],
    this.comparisons = const [],
    this.conclusion = '',
    this.assessmentResult,
    this.learningOutcomes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'generatedAt': generatedAt.toIso8601String(),
      if (mission != null) 'mission': mission!.toJson(),
      'trials': trials.map((trial) => trial.toJson()).toList(),
      'observations': observations,
      'comparisons': comparisons.map((item) => item.toJson()).toList(),
      'conclusion': conclusion,
      if (assessmentResult != null)
        'assessmentResult': assessmentResult!.toJson(),
      'learningOutcomes': learningOutcomes
          .map((item) => item.toJson())
          .toList(),
    };
  }
}
