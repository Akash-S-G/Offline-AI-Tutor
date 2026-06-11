enum LearningOutcomeStatus { achieved, partiallyAchieved, notAchieved }

class LearningOutcomeResult {
  final String outcomeId;
  final LearningOutcomeStatus status;
  final double evidenceScore;
  final String feedback;

  const LearningOutcomeResult({
    required this.outcomeId,
    required this.status,
    required this.evidenceScore,
    required this.feedback,
  });

  Map<String, dynamic> toJson() {
    return {
      'outcomeId': outcomeId,
      'status': status.name,
      'evidenceScore': evidenceScore,
      'feedback': feedback,
    };
  }
}
