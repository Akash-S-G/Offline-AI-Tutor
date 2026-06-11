class AssessmentResult {
  final String assessmentId;
  final Map<String, String> answers;
  final Map<String, bool> correctness;
  final double score;
  final double passingScore;
  final bool passed;
  final String feedback;
  final DateTime evaluatedAt;

  const AssessmentResult({
    required this.assessmentId,
    required this.answers,
    required this.correctness,
    required this.score,
    required this.passingScore,
    required this.passed,
    required this.feedback,
    required this.evaluatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'assessmentId': assessmentId,
      'answers': answers,
      'correctness': correctness,
      'score': score,
      'passingScore': passingScore,
      'passed': passed,
      'feedback': feedback,
      'evaluatedAt': evaluatedAt.toIso8601String(),
    };
  }
}
