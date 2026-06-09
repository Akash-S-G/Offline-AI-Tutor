import '../models/runtime_variable.dart';

class ComputedVariableDefinition {
  final String outputVariableId;
  final String type;
  final List<String> dependencies;
  final String? formula;

  const ComputedVariableDefinition({
    required this.outputVariableId,
    required this.type,
    required this.dependencies,
    this.formula,
  });
}

class RuntimeVariableDependencyGraph {
  final Map<String, ComputedVariableDefinition> _definitions = {};
  final Map<String, Set<String>> _dependentsByVariable = {};

  void rebuild(Iterable<RuntimeVariable> variables) {
    _definitions.clear();
    _dependentsByVariable.clear();

    for (final variable in variables) {
      final definition = definitionFromVariable(variable);
      if (definition == null) continue;
      _definitions[definition.outputVariableId] = definition;
      for (final dependency in definition.dependencies) {
        _dependentsByVariable
            .putIfAbsent(dependency, () => <String>{})
            .add(definition.outputVariableId);
      }
    }
  }

  ComputedVariableDefinition? definitionFor(String variableId) =>
      _definitions[variableId];

  List<ComputedVariableDefinition> get allDefinitions =>
      List.unmodifiable(_definitions.values.toList(growable: false));

  List<String> dependenciesFor(String variableId) =>
      List.unmodifiable(_definitions[variableId]?.dependencies ?? const []);

  Set<String> affectedBy(Iterable<String> changedVariableIds) {
    final affected = <String>{};
    final queue = <String>[...changedVariableIds];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final dependent in _dependentsByVariable[current] ?? const {}) {
        if (affected.add(dependent)) {
          queue.add(dependent);
        }
      }
    }
    return affected;
  }

  static ComputedVariableDefinition? definitionFromVariable(
    RuntimeVariable variable,
  ) {
    if (!_computedTypes.contains(variable.type)) return null;
    final dependencies = _dependenciesFor(variable);
    return ComputedVariableDefinition(
      outputVariableId: variable.id,
      type: variable.type,
      dependencies: dependencies,
      formula: _stringMetadata(variable.metadata, ['formula', 'expression']),
    );
  }

  static List<String> _dependenciesFor(RuntimeVariable variable) {
    final metadata = variable.metadata;
    final explicit = _listMetadata(metadata, [
      'dependencies',
      'dependencyIds',
      'inputVariables',
      'inputs',
      'variables',
    ]);
    if (explicit.isNotEmpty) return explicit;

    switch (variable.type) {
      case 'velocity':
        return _specific(metadata, ['distanceVariable', 'distanceId']) +
            _specific(metadata, ['timeVariable', 'timeId']);
      case 'acceleration':
        return _specific(metadata, [
              'initialVelocityVariable',
              'previousVelocityVariable',
              'startVelocityVariable',
            ]) +
            _specific(metadata, [
              'velocityVariable',
              'finalVelocityVariable',
              'currentVelocityVariable',
            ]) +
            _specific(metadata, ['timeVariable', 'timeId']);
      case 'distance':
        return _specific(metadata, ['speedVariable', 'speedId']) +
            _specific(metadata, ['timeVariable', 'timeId']);
      case 'force':
        return _specific(metadata, ['massVariable', 'massId']) +
            _specific(metadata, ['accelerationVariable', 'accelerationId']);
      case 'power':
        return _specific(metadata, ['forceVariable', 'forceId']) +
            _specific(metadata, ['velocityVariable', 'velocityId']);
      case 'energy':
        return _specific(metadata, ['powerVariable', 'powerId']) +
            _specific(metadata, ['timeVariable', 'timeId']);
      default:
        return const [];
    }
  }

  static List<String> _specific(
    Map<String, dynamic> metadata,
    List<String> keys,
  ) {
    final value = _stringMetadata(metadata, keys);
    return value == null || value.isEmpty ? const [] : [value];
  }

  static List<String> _listMetadata(
    Map<String, dynamic> metadata,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = metadata[key];
      if (value is List) {
        return value
            .map((entry) => entry?.toString() ?? '')
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
      }
      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(',')
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
      }
    }
    return const [];
  }

  static String? _stringMetadata(
    Map<String, dynamic> metadata,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = metadata[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static const Set<String> _computedTypes = {
    'average',
    'minimum',
    'maximum',
    'velocity',
    'acceleration',
    'distance',
    'force',
    'power',
    'energy',
  };
}
