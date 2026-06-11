enum AssessmentQuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
  observationReflection,
}

class AssessmentQuestion {
  final String id;
  final String prompt;
  final AssessmentQuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final double points;

  const AssessmentQuestion({
    required this.id,
    required this.prompt,
    required this.type,
    this.options = const [],
    this.correctAnswer = '',
    this.explanation = '',
    this.points = 1,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      id: json['id']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? json['question']?.toString() ?? '',
      type: assessmentQuestionTypeFromString(json['type']?.toString()),
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((option) => option.toString())
          .toList(growable: false),
      correctAnswer:
          json['correctAnswer']?.toString() ?? json['answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      points: json['points'] is num
          ? (json['points'] as num).toDouble()
          : double.tryParse(json['points']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'type': type.name,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
    };
  }

  bool isAutoGradable() {
    return type != AssessmentQuestionType.observationReflection &&
        type != AssessmentQuestionType.shortAnswer;
  }

  bool isCorrect(String answer) {
    if (!isAutoGradable()) return answer.trim().isNotEmpty;
    return answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }
}

AssessmentQuestionType assessmentQuestionTypeFromString(String? value) {
  switch (value) {
    case 'trueFalse':
      return AssessmentQuestionType.trueFalse;
    case 'shortAnswer':
      return AssessmentQuestionType.shortAnswer;
    case 'observationReflection':
    case 'reflection':
      return AssessmentQuestionType.observationReflection;
    case 'multipleChoice':
    default:
      return AssessmentQuestionType.multipleChoice;
  }
}
