import '../conditions/task_completion_condition.dart';

class ExperimentTask {
  final String id;
  final String title;
  final String description;
  final TaskCompletionCondition condition;
  final bool completed;
  final DateTime? completedAt;

  const ExperimentTask({
    required this.id,
    required this.title,
    required this.description,
    required this.condition,
    this.completed = false,
    this.completedAt,
  });

  factory ExperimentTask.fromJson(Map<String, dynamic> json) {
    return ExperimentTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Task',
      description: json['description']?.toString() ?? '',
      condition: TaskCompletionCondition.fromJson(
        Map<String, dynamic>.from(
          json['condition'] as Map? ??
              json['completionCondition'] as Map? ??
              const {},
        ),
      ),
      completed: json['completed'] == true,
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
    );
  }

  ExperimentTask copyWith({bool? completed, DateTime? completedAt}) {
    return ExperimentTask(
      id: id,
      title: title,
      description: description,
      condition: condition,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'condition': condition.toJson(),
      'completed': completed,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }
}
