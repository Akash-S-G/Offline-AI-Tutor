class AssessmentAnalytics {
  int assessmentsStarted = 0;
  int assessmentsCompleted = 0;
  int reportsGenerated = 0;
  int outcomesAchieved = 0;
  double _scoreTotal = 0;

  double get averageAssessmentScore {
    if (assessmentsCompleted <= 0) return 0;
    return _scoreTotal / assessmentsCompleted;
  }

  void recordAssessmentScore(double score) {
    assessmentsCompleted++;
    _scoreTotal += score;
  }

  Map<String, dynamic> toJson() {
    return {
      'assessmentsStarted': assessmentsStarted,
      'assessmentsCompleted': assessmentsCompleted,
      'reportsGenerated': reportsGenerated,
      'outcomesAchieved': outcomesAchieved,
      'averageAssessmentScore': averageAssessmentScore,
    };
  }
}
