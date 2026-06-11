class GuidedProgressTracker {
  final int objectiveCount;
  final int questionCount;
  final int requiredObservationRows;
  final int stepCount;
  final Set<String> completedObjectives;
  final Set<String> answeredQuestions;
  final Set<String> completedSteps;
  final int observationRows;

  const GuidedProgressTracker({
    required this.objectiveCount,
    required this.questionCount,
    required this.requiredObservationRows,
    required this.stepCount,
    this.completedObjectives = const {},
    this.answeredQuestions = const {},
    this.completedSteps = const {},
    this.observationRows = 0,
  });

  double get completionPercent {
    final total =
        objectiveCount + questionCount + requiredObservationRows + stepCount;
    if (total <= 0) return 100;
    final completed =
        completedObjectives.length +
        answeredQuestions.length +
        observationRows.clamp(0, requiredObservationRows) +
        completedSteps.length;
    return ((completed / total) * 100).clamp(0, 100).toDouble();
  }

  bool get complete => completionPercent >= 100;

  GuidedProgressTracker copyWith({
    Set<String>? completedObjectives,
    Set<String>? answeredQuestions,
    Set<String>? completedSteps,
    int? observationRows,
  }) {
    return GuidedProgressTracker(
      objectiveCount: objectiveCount,
      questionCount: questionCount,
      requiredObservationRows: requiredObservationRows,
      stepCount: stepCount,
      completedObjectives: completedObjectives ?? this.completedObjectives,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      completedSteps: completedSteps ?? this.completedSteps,
      observationRows: observationRows ?? this.observationRows,
    );
  }
}
