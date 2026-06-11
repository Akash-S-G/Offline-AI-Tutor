import 'completion_condition.dart';
import 'step_type.dart';

class ExperimentStep {
  final String id;
  final String title;
  final String instruction;
  final StepType type;
  final CompletionCondition completionCondition;
  final bool isOptional;
  final Map<String, dynamic> metadata;

  const ExperimentStep({
    required this.id,
    required this.title,
    required this.instruction,
    required this.type,
    required this.completionCondition,
    this.isOptional = false,
    this.metadata = const {},
  });

  factory ExperimentStep.fromJson(Map<String, dynamic> json) {
    return ExperimentStep(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Experiment Step',
      instruction: json['instruction']?.toString() ?? '',
      type: stepTypeFromString(json['type']?.toString()),
      completionCondition: CompletionCondition.fromJson(
        json['completionCondition'] as Map<String, dynamic>?,
      ),
      isOptional: json['isOptional'] == true,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'instruction': instruction,
      'type': type.name,
      'completionCondition': completionCondition.toJson(),
      'isOptional': isOptional,
      'metadata': metadata,
    };
  }
}
