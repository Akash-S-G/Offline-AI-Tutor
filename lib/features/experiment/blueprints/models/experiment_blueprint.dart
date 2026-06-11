import 'experiment_category.dart';
import 'experiment_objective.dart';
import 'experiment_observation_template.dart';
import 'experiment_parameter.dart';
import 'experiment_question.dart';
import '../../assessment/models/experiment_assessment.dart';
import '../../assessment/models/learning_outcome.dart';
import '../../guided_runtime/models/experiment_mission.dart';

class ExperimentBlueprint {
  final String id;
  final String name;
  final String subject;
  final String topic;
  final String description;
  final String grade;
  final String difficulty;
  final String estimatedTime;
  final String visualPreset;
  final ExperimentMission? mission;
  final Map<String, dynamic> investigation;
  final ExperimentAssessment? assessment;
  final List<LearningOutcome> learningOutcomes;
  final ExperimentCategory category;
  final List<ExperimentObjective> objectives;
  final List<ExperimentParameter> parameters;
  final List<ExperimentQuestion> questions;
  final ExperimentObservationTemplate observationTemplate;
  final Map<String, dynamic> manifest;

  const ExperimentBlueprint({
    required this.id,
    required this.name,
    required this.subject,
    required this.topic,
    required this.description,
    required this.objectives,
    required this.parameters,
    required this.questions,
    required this.observationTemplate,
    required this.manifest,
    this.grade = 'General',
    this.difficulty = 'Medium',
    this.estimatedTime = '15 mins',
    this.visualPreset = '',
    this.mission,
    this.investigation = const {},
    this.assessment,
    this.learningOutcomes = const [],
    this.category = ExperimentCategory.generalScience,
  });

  factory ExperimentBlueprint.fromJson(Map<String, dynamic> json) {
    return ExperimentBlueprint(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Experiment',
      subject: json['subject']?.toString() ?? 'Science',
      topic: json['topic']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      grade: json['grade']?.toString() ?? 'General',
      difficulty: json['difficulty']?.toString() ?? 'Medium',
      estimatedTime: json['estimatedTime']?.toString() ?? '15 mins',
      visualPreset: json['visualPreset']?.toString() ?? '',
      mission: json['mission'] is Map
          ? ExperimentMission.fromJson(
              Map<String, dynamic>.from(json['mission'] as Map),
            )
          : null,
      investigation: Map<String, dynamic>.from(
        json['investigation'] as Map? ?? const {},
      ),
      assessment: json['assessment'] is Map
          ? ExperimentAssessment.fromJson(
              Map<String, dynamic>.from(json['assessment'] as Map),
            )
          : null,
      learningOutcomes: (json['learningOutcomes'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => LearningOutcome.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      category: experimentCategoryFromString(json['category']?.toString()),
      objectives: (json['objectives'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ExperimentObjective.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      parameters: (json['parameters'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ExperimentParameter.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ExperimentQuestion.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      observationTemplate: ExperimentObservationTemplate.fromJson(
        Map<String, dynamic>.from(
          json['observationTemplate'] as Map? ?? const {},
        ),
      ),
      manifest: Map<String, dynamic>.from(json['manifest'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'topic': topic,
      'description': description,
      'grade': grade,
      'difficulty': difficulty,
      'estimatedTime': estimatedTime,
      'visualPreset': visualPreset,
      if (mission != null) 'mission': mission!.toJson(),
      if (investigation.isNotEmpty) 'investigation': investigation,
      if (assessment != null) 'assessment': assessment!.toJson(),
      if (learningOutcomes.isNotEmpty)
        'learningOutcomes': learningOutcomes
            .map((outcome) => outcome.toJson())
            .toList(),
      'category': category.name,
      'objectives': objectives.map((objective) => objective.toJson()).toList(),
      'parameters': parameters.map((parameter) => parameter.toJson()).toList(),
      'questions': questions.map((question) => question.toJson()).toList(),
      'observationTemplate': observationTemplate.toJson(),
      'manifest': manifest,
    };
  }
}
