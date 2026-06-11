import '../../guided_runtime/models/experiment_mission.dart';
import '../../investigation/models/experiment_trial.dart';
import '../../investigation/models/trial_comparison.dart';
import '../analytics/assessment_analytics.dart';
import '../models/assessment_result.dart';
import '../models/experiment_lab_report.dart';
import '../models/learning_outcome_result.dart';

class LabReportBuilder {
  final AssessmentAnalytics analytics;

  const LabReportBuilder({required this.analytics});

  ExperimentLabReport build({
    required String title,
    ExperimentMission? mission,
    required List<ExperimentTrial> trials,
    List<TrialComparison> comparisons = const [],
    String conclusion = '',
    AssessmentResult? assessmentResult,
    List<LearningOutcomeResult> learningOutcomes = const [],
  }) {
    analytics.reportsGenerated++;
    return ExperimentLabReport(
      id: 'report_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      generatedAt: DateTime.now(),
      mission: mission,
      trials: trials,
      observations: trials
          .expand((trial) => trial.observations.map((item) => item.toJson()))
          .toList(growable: false),
      comparisons: comparisons,
      conclusion: conclusion,
      assessmentResult: assessmentResult,
      learningOutcomes: learningOutcomes,
    );
  }
}
