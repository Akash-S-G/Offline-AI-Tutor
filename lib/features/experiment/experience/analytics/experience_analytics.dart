class ExperienceAnalytics {
  int _experimentsStarted = 0;
  int _experimentsCompleted = 0;
  int _stepsCompleted = 0;
  int _questionsAnswered = 0;
  double _completionRateTotal = 0;
  double _durationTotalSeconds = 0;

  int get experimentsStarted => _experimentsStarted;
  int get experimentsCompleted => _experimentsCompleted;
  int get stepsCompleted => _stepsCompleted;
  int get questionsAnswered => _questionsAnswered;
  double get averageCompletionRate => _experimentsCompleted == 0
      ? 0
      : _completionRateTotal / _experimentsCompleted;
  double get averageExperimentDuration => _experimentsCompleted == 0
      ? 0
      : _durationTotalSeconds / _experimentsCompleted;

  void recordStarted() {
    _experimentsStarted++;
  }

  void recordStepCompleted() {
    _stepsCompleted++;
  }

  void recordQuestionAnswered() {
    _questionsAnswered++;
  }

  void recordCompleted({
    required double completionRate,
    required Duration duration,
  }) {
    _experimentsCompleted++;
    _completionRateTotal += completionRate;
    _durationTotalSeconds += duration.inMilliseconds / 1000;
  }

  Map<String, dynamic> toJson() {
    return {
      'experimentsStarted': experimentsStarted,
      'experimentsCompleted': experimentsCompleted,
      'stepsCompleted': stepsCompleted,
      'questionsAnswered': questionsAnswered,
      'averageCompletionRate': averageCompletionRate,
      'averageExperimentDuration': averageExperimentDuration,
    };
  }
}
