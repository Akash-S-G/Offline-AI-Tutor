class RuntimeExperienceState {
  final int currentStepIndex;
  final Set<String> completedSteps;
  final double progress;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int observationCount;
  final int questionCount;

  const RuntimeExperienceState({
    this.currentStepIndex = 0,
    this.completedSteps = const {},
    this.progress = 0,
    this.startedAt,
    this.completedAt,
    this.observationCount = 0,
    this.questionCount = 0,
  });

  bool get isCompleted => completedAt != null;

  RuntimeExperienceState copyWith({
    int? currentStepIndex,
    Set<String>? completedSteps,
    double? progress,
    DateTime? startedAt,
    DateTime? completedAt,
    int? observationCount,
    int? questionCount,
  }) {
    return RuntimeExperienceState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completedSteps: completedSteps ?? this.completedSteps,
      progress: progress ?? this.progress,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      observationCount: observationCount ?? this.observationCount,
      questionCount: questionCount ?? this.questionCount,
    );
  }
}
