import '../rubrics/assessment_rubric.dart';
import 'assessment_question.dart';

class ExperimentAssessment {
  final String id;
  final String title;
  final String description;
  final List<AssessmentQuestion> questions;
  final double passingScore;
  final AssessmentRubric rubric;

  const ExperimentAssessment({
    required this.id,
    required this.title,
    required this.description,
    this.questions = const [],
    this.passingScore = 70,
    this.rubric = const AssessmentRubric(),
  });

  factory ExperimentAssessment.fromJson(Map<String, dynamic> json) {
    return ExperimentAssessment(
      id: json['id']?.toString() ?? 'assessment',
      title: json['title']?.toString() ?? 'Experiment Assessment',
      description: json['description']?.toString() ?? '',
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AssessmentQuestion.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      passingScore: json['passingScore'] is num
          ? (json['passingScore'] as num).toDouble()
          : double.tryParse(json['passingScore']?.toString() ?? '') ?? 70,
      rubric: json['rubric'] is Map
          ? AssessmentRubric.fromJson(
              Map<String, dynamic>.from(json['rubric'] as Map),
            )
          : AssessmentRubric.defaultRubric(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((question) => question.toJson()).toList(),
      'passingScore': passingScore,
      'rubric': rubric.toJson(),
    };
  }
}
