class QuizResult {
  final int? id;
  final String chapterId;
  final int score;
  final int totalQuestions;
  final Map<int, int> answers;
  final DateTime attemptedAt;

  QuizResult({
    this.id,
    required this.chapterId,
    required this.score,
    required this.totalQuestions,
    required this.answers,
    required this.attemptedAt,
  });

  int get percentage => ((score * 100) / totalQuestions).round();

  bool get passed => percentage >= 60;

  String get performanceLabel {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 80) return 'Very Good';
    if (percentage >= 70) return 'Good';
    if (percentage >= 60) return 'Passed';
    return 'Needs Improvement';
  }
}
