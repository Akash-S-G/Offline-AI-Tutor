import '../models/experiment_builder_state.dart';

class BuilderValidationResult {
  final bool isValid;
  final List<String> errors;

  BuilderValidationResult({required this.isValid, required this.errors});
}

class BuilderValidator {
  BuilderValidationResult validate(ExperimentBuilderState state) {
    final errors = <String>[];

    // Check Scene
    if (state.scene.name.trim().isEmpty) {
      errors.add('Scene name cannot be empty.');
    }

    // Check Variables
    final variableIds = <String>{};
    for (final v in state.variables) {
      if (v.id.trim().isEmpty) errors.add('Variable ID cannot be empty.');
      if (variableIds.contains(v.id)) {
        errors.add('Duplicate Variable ID: ${v.id}');
      } else {
        variableIds.add(v.id);
      }
      if (v.name.trim().isEmpty) errors.add('Variable name cannot be empty for ${v.id}.');
    }

    // Check Objects
    final objectIds = <String>{};
    for (final o in state.objects) {
      if (o.id.trim().isEmpty) errors.add('Object ID cannot be empty.');
      if (objectIds.contains(o.id)) {
        errors.add('Duplicate Object ID: ${o.id}');
      } else {
        objectIds.add(o.id);
      }
      if (o.name.trim().isEmpty) errors.add('Object name cannot be empty for ${o.id}.');
    }

    // Check Rules
    final ruleIds = <String>{};
    for (final r in state.rules) {
      if (r.id.trim().isEmpty) errors.add('Rule ID cannot be empty.');
      if (ruleIds.contains(r.id)) {
        errors.add('Duplicate Rule ID: ${r.id}');
      } else {
        ruleIds.add(r.id);
      }
      if (r.name.trim().isEmpty) errors.add('Rule name cannot be empty for ${r.id}.');
      if (r.condition.isEmpty) errors.add('Rule ${r.name} cannot have an empty condition.');
      if (r.action.isEmpty) errors.add('Rule ${r.name} cannot have an empty action.');
    }

    // Optional: Check if rule references missing variables or objects
    for (final o in state.objects) {
      if (o.properties.containsKey('linked_variable')) {
        final vId = o.properties['linked_variable'];
        if (!variableIds.contains(vId)) {
          errors.add('Object ${o.name} references missing variable: $vId');
        }
      }
    }

    return BuilderValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
