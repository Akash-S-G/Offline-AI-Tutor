import '../analytics/assessment_analytics.dart';
import '../models/assessment_result.dart';
import '../models/learning_outcome.dart';
import '../models/learning_outcome_result.dart';

class LearningOutcomeEvaluator {
  final AssessmentAnalytics analytics;

  const LearningOutcomeEvaluator({required this.analytics});

  List<LearningOutcomeResult> evaluate({
    required List<LearningOutcome> outcomes,
    AssessmentResult? assessmentResult,
    required bool missionCompleted,
    required int completedTrials,
  }) {
    final score = _evidenceScore(
      assessmentResult: assessmentResult,
      missionCompleted: missionCompleted,
      completedTrials: completedTrials,
    );
    return outcomes
        .map((outcome) {
          final status = score >= 75
              ? LearningOutcomeStatus.achieved
              : score >= 45
              ? LearningOutcomeStatus.partiallyAchieved
              : LearningOutcomeStatus.notAchieved;
          if (status == LearningOutcomeStatus.achieved) {
            analytics.outcomesAchieved++;
          }
          return LearningOutcomeResult(
            outcomeId: outcome.id,
            status: status,
            evidenceScore: score,
            feedback: _feedback(status, outcome),
          );
        })
        .toList(growable: false);
  }

  double _evidenceScore({
    AssessmentResult? assessmentResult,
    required bool missionCompleted,
    required int completedTrials,
  }) {
    final assessmentScore = assessmentResult?.score ?? 0;
    final missionScore = missionCompleted ? 20 : 0;
    final trialScore = completedTrials >= 2 ? 20 : completedTrials * 10;
    return (assessmentScore * 0.6 + missionScore + trialScore)
        .clamp(0, 100)
        .toDouble();
  }

  String _feedback(LearningOutcomeStatus status, LearningOutcome outcome) {
    switch (status) {
      case LearningOutcomeStatus.achieved:
        return 'Achieved: ${outcome.description}';
      case LearningOutcomeStatus.partiallyAchieved:
        return 'Partially achieved: ${outcome.description}';
      case LearningOutcomeStatus.notAchieved:
        return 'Not achieved yet: ${outcome.description}';
    }
  }
}
