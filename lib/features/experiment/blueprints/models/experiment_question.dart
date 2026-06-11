enum QuestionType { mcq, shortAnswer, prediction, observation }

QuestionType questionTypeFromString(String? value) {
  return QuestionType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => QuestionType.shortAnswer,
  );
}

class ExperimentQuestion {
  final String id;
  final QuestionType type;
  final String question;
  final List<String> options;
  final dynamic correctAnswer;
  final String explanation;
  final bool required;

  const ExperimentQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.options = const [],
    this.correctAnswer,
    this.explanation = '',
    this.required = true,
  });

  factory ExperimentQuestion.fromJson(Map<String, dynamic> json) {
    return ExperimentQuestion(
      id: json['id']?.toString() ?? '',
      type: questionTypeFromString(json['type']?.toString()),
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((option) => option.toString())
          .toList(growable: false),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation']?.toString() ?? '',
      required: json['required'] is bool ? json['required'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'question': question,
      'options': options,
      if (correctAnswer != null) 'correctAnswer': correctAnswer,
      'explanation': explanation,
      'required': required,
    };
  }
}
