enum ExperimentQuestionType { multipleChoice, trueFalse, shortAnswer }

class ExperimentQuestion {
  final String id;
  final String question;
  final ExperimentQuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  const ExperimentQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    this.correctAnswer = '',
    this.explanation = '',
  });

  factory ExperimentQuestion.fromJson(Map<String, dynamic> json) {
    return ExperimentQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      type: _typeFromString(json['type']?.toString()),
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((option) => option.toString())
          .toList(growable: false),
      correctAnswer:
          json['correctAnswer']?.toString() ?? json['answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type.name,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  bool isCorrect(String answer) {
    if (correctAnswer.trim().isEmpty) return answer.trim().isNotEmpty;
    return answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }

  static ExperimentQuestionType _typeFromString(String? raw) {
    switch (raw) {
      case 'trueFalse':
        return ExperimentQuestionType.trueFalse;
      case 'shortAnswer':
        return ExperimentQuestionType.shortAnswer;
      default:
        return ExperimentQuestionType.multipleChoice;
    }
  }
}
