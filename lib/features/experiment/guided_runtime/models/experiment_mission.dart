import 'experiment_question.dart';
import 'experiment_task.dart';

class ExperimentMission {
  final String id;
  final String title;
  final String objective;
  final String description;
  final String difficulty;
  final Duration estimatedDuration;
  final List<ExperimentTask> tasks;
  final List<ExperimentQuestion> questions;

  const ExperimentMission({
    required this.id,
    required this.title,
    required this.objective,
    required this.description,
    required this.difficulty,
    required this.estimatedDuration,
    this.tasks = const [],
    this.questions = const [],
  });

  factory ExperimentMission.fromJson(Map<String, dynamic> json) {
    return ExperimentMission(
      id: json['id']?.toString() ?? 'mission',
      title: json['title']?.toString() ?? 'Experiment Mission',
      objective: json['objective']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      estimatedDuration: Duration(
        seconds: _durationSeconds(json['estimatedDuration']),
      ),
      tasks: (json['tasks'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ExperimentTask.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ExperimentQuestion.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'objective': objective,
      'description': description,
      'difficulty': difficulty,
      'estimatedDuration': estimatedDuration.inSeconds,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'questions': questions.map((question) => question.toJson()).toList(),
    };
  }

  static int _durationSeconds(dynamic value) {
    if (value is Duration) return value.inSeconds;
    if (value is num) return value.toInt();
    final raw = value?.toString() ?? '';
    final parsed = int.tryParse(raw);
    if (parsed != null) return parsed;
    final minutes = RegExp(r'(\d+)').firstMatch(raw)?.group(1);
    return (int.tryParse(minutes ?? '') ?? 5) * 60;
  }
}
