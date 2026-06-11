import '../models/experiment_blueprint.dart';
import '../models/experiment_question.dart';

class BlueprintValidationResult {
  final bool valid;
  final List<String> errors;

  const BlueprintValidationResult({
    required this.valid,
    this.errors = const [],
  });
}

class BlueprintValidator {
  BlueprintValidationResult validate(ExperimentBlueprint blueprint) {
    final errors = <String>[];
    if (blueprint.manifest.isEmpty) {
      errors.add('Manifest exists: FAILED');
    }
    final scene = blueprint.manifest['scene'];
    if (scene is! Map) {
      errors.add('Manifest scene exists: FAILED');
      return BlueprintValidationResult(valid: errors.isEmpty, errors: errors);
    }
    final variables = (scene['variables'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .toList(growable: false);
    if (variables.isEmpty) errors.add('Variables exist: FAILED');
    final variableIds = variables
        .map((variable) => variable['id']?.toString())
        .toSet();
    for (final parameter in blueprint.parameters) {
      if (!variableIds.contains(parameter.variableId)) {
        errors.add(
          'Parameter ${parameter.displayName} references missing variable ${parameter.variableId}',
        );
      }
      if (parameter.minValue >= parameter.maxValue) {
        errors.add(
          'Parameter ${parameter.displayName} min must be less than max',
        );
      }
    }
    if (blueprint.observationTemplate.columns.isEmpty) {
      errors.add('Observation columns valid: FAILED');
    }
    if (blueprint.observationTemplate.requiredRows <= 0) {
      errors.add('Observation required rows must be positive');
    }
    for (final question in blueprint.questions) {
      if (question.question.trim().isEmpty) {
        errors.add('Question ${question.id} is empty');
      }
      if (question.type == QuestionType.mcq && question.options.length < 2) {
        errors.add('MCQ ${question.id} must have at least two options');
      }
    }
    if (blueprint.objectives.isEmpty) {
      errors.add('Objectives exist: FAILED');
    }
    return BlueprintValidationResult(valid: errors.isEmpty, errors: errors);
  }
}
