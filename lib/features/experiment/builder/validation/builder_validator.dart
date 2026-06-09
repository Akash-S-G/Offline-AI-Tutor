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
    final variableNamesById = <String, String>{};
    for (final v in state.variables) {
      if (v.id.trim().isEmpty) errors.add('Variable ID cannot be empty.');
      if (variableIds.contains(v.id)) {
        errors.add('Duplicate Variable ID: ${v.id}');
      } else {
        variableIds.add(v.id);
      }
      if (v.name.trim().isEmpty) {
        errors.add('Variable name cannot be empty for ${v.id}.');
      }
      variableNamesById[v.id] = v.name;
    }

    // Check Objects
    final objectIds = <String>{};
    final objectNamesById = <String, String>{};
    for (final o in state.objects) {
      if (o.id.trim().isEmpty) errors.add('Object ID cannot be empty.');
      if (objectIds.contains(o.id)) {
        errors.add('Duplicate Object ID: ${o.id}');
      } else {
        objectIds.add(o.id);
      }
      if (o.name.trim().isEmpty) {
        errors.add('Object name cannot be empty for ${o.id}.');
      }
      objectNamesById[o.id] = o.name;
    }

    for (final o in state.objects) {
      for (final missing in _missingVariableRefs(o.properties, variableIds)) {
        errors.add(
          'Object "${o.name}" references missing variable "${_variableLabel(missing, variableNamesById)}".',
        );
      }
      for (final missing in _missingObjectRefs(o.properties, objectIds)) {
        errors.add(
          'Object "${o.name}" references missing object "${_objectLabel(missing, objectNamesById)}".',
        );
      }
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
      if (r.name.trim().isEmpty) {
        errors.add('Rule name cannot be empty for ${r.id}.');
      }
      if (r.condition.isEmpty) {
        errors.add('Rule ${r.name} cannot have an empty condition.');
      }
      if (r.action.isEmpty) {
        errors.add('Rule ${r.name} cannot have an empty action.');
      }
      final rulePayload = {'condition': r.condition, 'action': r.action};
      for (final missing in _missingVariableRefs(rulePayload, variableIds)) {
        errors.add(
          'Rule "${r.name}" references missing variable "${_variableLabel(missing, variableNamesById)}".',
        );
      }
      for (final missing in _missingObjectRefs(rulePayload, objectIds)) {
        errors.add(
          'Rule "${r.name}" references missing object "${_objectLabel(missing, objectNamesById)}".',
        );
      }
    }

    return BuilderValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  Set<String> _missingVariableRefs(dynamic value, Set<String> variableIds) {
    return _missingRefs(
      value,
      validIds: variableIds,
      keyMatchers: const {
        'variableId',
        'linked_variable',
        'water_var',
        'sun_var',
        'temp_var',
      },
      prefix: 'var_',
    );
  }

  Set<String> _missingObjectRefs(dynamic value, Set<String> objectIds) {
    return _missingRefs(
      value,
      validIds: objectIds,
      keyMatchers: const {'objectId', 'targetObjectId', 'sourceObjectId'},
      prefix: 'obj_',
    );
  }

  Set<String> _missingRefs(
    dynamic value, {
    required Set<String> validIds,
    required Set<String> keyMatchers,
    required String prefix,
  }) {
    final missing = <String>{};
    void scan(dynamic node, [String? parentKey]) {
      if (node is Map) {
        for (final entry in node.entries) {
          scan(entry.value, entry.key.toString());
        }
      } else if (node is Iterable) {
        for (final item in node) {
          scan(item, parentKey);
        }
      } else if (node is String) {
        final isReferenceKey =
            parentKey != null && keyMatchers.contains(parentKey);
        final looksLikeId = node.startsWith(prefix);
        if ((isReferenceKey || looksLikeId) && !validIds.contains(node)) {
          missing.add(node);
        }
      }
    }

    scan(value);
    return missing;
  }

  String _variableLabel(String id, Map<String, String> variableNamesById) {
    final name = variableNamesById[id];
    return name == null ? id : '$name ($id)';
  }

  String _objectLabel(String id, Map<String, String> objectNamesById) {
    final name = objectNamesById[id];
    return name == null ? id : '$name ($id)';
  }
}
