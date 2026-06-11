class GuidedRuntimeAnalytics {
  int missionsStarted = 0;
  int missionsCompleted = 0;
  int tasksStarted = 0;
  int tasksCompleted = 0;
  int questionsAnswered = 0;
  int questionsCorrect = 0;
  int questionsIncorrect = 0;
  int guidedFailures = 0;

  Map<String, int> toJson() => {
    'missionsStarted': missionsStarted,
    'missionsCompleted': missionsCompleted,
    'tasksStarted': tasksStarted,
    'tasksCompleted': tasksCompleted,
    'questionsAnswered': questionsAnswered,
    'questionsCorrect': questionsCorrect,
    'questionsIncorrect': questionsIncorrect,
    'guidedFailures': guidedFailures,
  };
}
