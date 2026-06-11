import '../models/experiment_question.dart';

class GuidedQuestionEngine {
  final List<ExperimentQuestion> questions;
  final Map<String, dynamic> _answers = {};

  GuidedQuestionEngine({required this.questions});

  Map<String, dynamic> get answers => Map.unmodifiable(_answers);

  void submitAnswer(String questionId, dynamic answer) {
    _answers[questionId] = answer;
  }

  bool isAnswered(String questionId) => _answers.containsKey(questionId);

  bool get allRequiredAnswered {
    return questions.where((question) => question.required).every((question) {
      return isAnswered(question.id);
    });
  }
}
