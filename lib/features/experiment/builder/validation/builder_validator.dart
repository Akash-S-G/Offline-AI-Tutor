import '../models/builder_object.dart';
import '../models/builder_rule.dart';
import '../models/builder_variable.dart';
import '../models/experiment_builder_state.dart';
import '../../runtime/sensors/models/runtime_sensor_type.dart';
import '../../runtime/sensors/sensor_registry.dart';

class BuilderValidationResult {
  final bool isValid;
  final List<String> errors;

  BuilderValidationResult({required this.isValid, required this.errors});
}

class BuilderValidator {
  BuilderValidationResult validate(ExperimentBuilderState state) {
    final errors = <String>[];
    final sensorRegistry = SensorRegistry();

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
      final sensorType = runtimeSensorTypeFromVariableType(v.type);
      if (sensorType != null &&
          !sensorRegistry.hasProvider(sensorType.providerType)) {
        errors.add(
          'Variable "${v.name}" uses unknown sensor provider "${sensorType.name}".',
        );
      }
      variableNamesById[v.id] = v.name;
    }

    for (final v in state.variables) {
      for (final error in _variableRuntimeConfigErrors(v, variableIds)) {
        errors.add(error);
      }
    }
    for (final cycle in _dependencyCycles(state.variables)) {
      errors.add('Circular dependency detected: ${cycle.join(' -> ')}');
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
      for (final missing in _missingVariableRefs(
        o.runtimeConfig,
        variableIds,
      )) {
        errors.add(
          'Object "${o.name}" references missing variable "${_variableLabel(missing, variableNamesById)}".',
        );
      }
      for (final missing in _missingObjectRefs(o.properties, objectIds)) {
        errors.add(
          'Object "${o.name}" references missing object "${_objectLabel(missing, objectNamesById)}".',
        );
      }
      for (final error in _runtimeConfigErrors(o, variableIds)) {
        errors.add(error);
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
      for (final error in _ruleRuntimeConfigErrors(
        r,
        variables: state.variables,
        objectIds: objectIds,
      )) {
        errors.add(error);
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
        'variable',
        'xVariable',
        'yVariable',
        'x_variable',
        'y_variable',
        'valueVariable',
        'linkedVariable',
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

  List<String> _variableRuntimeConfigErrors(
    dynamic variable,
    Set<String> variableIds,
  ) {
    final v = variable as dynamic;
    final config = Map<String, dynamic>.from(v.runtimeConfig as Map);
    final errors = <String>[];
    num? number(String key) {
      final value = config[key];
      if (value is num) return value;
      return num.tryParse(value?.toString() ?? '');
    }

    bool exists(String? id) =>
        id != null && id.isNotEmpty && variableIds.contains(id);
    void requireRef(String key) {
      final id = config[key]?.toString();
      if (!exists(id)) {
        errors.add(
          '${v.name} variable references missing variable ${id ?? key}',
        );
      }
    }

    switch (v.type.toString()) {
      case 'countdown':
        if ((number('startValue') ?? 0) <= 0) {
          errors.add('${v.name} countdown startValue must be > 0.');
        }
        break;
      case 'interval':
        if ((number('intervalSeconds') ?? 0) <= 0) {
          errors.add('${v.name} intervalSeconds must be > 0.');
        }
        break;
      case 'average':
      case 'minimum':
      case 'maximum':
        final dependencies = _dependenciesFromConfig(v.type.toString(), config);
        if (dependencies.length < 2) {
          errors.add('${v.name} requires at least 2 dependencies.');
        }
        for (final id in dependencies) {
          if (!exists(id)) {
            errors.add('${v.name} variable references missing variable $id');
          }
        }
        break;
      case 'distance':
        requireRef('speedVariable');
        requireRef('timeVariable');
        break;
      case 'velocity':
        requireRef('distanceVariable');
        requireRef('timeVariable');
        break;
      case 'acceleration':
        requireRef('velocityVariable');
        requireRef('timeVariable');
        break;
      case 'force':
        requireRef('massVariable');
        requireRef('accelerationVariable');
        break;
      case 'power':
        requireRef('forceVariable');
        requireRef('velocityVariable');
        break;
      case 'energy':
        requireRef('powerVariable');
        requireRef('timeVariable');
        break;
    }
    return errors;
  }

  List<String> _ruleRuntimeConfigErrors(
    BuilderRule rule, {
    required List<BuilderVariable> variables,
    required Set<String> objectIds,
  }) {
    final errors = <String>[];
    final variableIds = variables.map((variable) => variable.id).toSet();
    final variablesById = {
      for (final variable in variables) variable.id: variable,
    };
    final condition = rule.condition;
    final conditionVariableId = condition['variableId']?.toString();
    final operator = condition['operator']?.toString();
    if (conditionVariableId == null ||
        conditionVariableId.isEmpty ||
        !variableIds.contains(conditionVariableId)) {
      errors.add(
        'Rule "${rule.name}" condition references missing variable ${conditionVariableId ?? ''}.',
      );
    }
    if (!const {'==', '!=', '>', '>=', '<', '<='}.contains(operator)) {
      errors.add(
        'Rule "${rule.name}" condition has unsupported operator ${operator ?? ''}.',
      );
    }
    if (!condition.containsKey('value')) {
      errors.add('Rule "${rule.name}" condition value is required.');
    }

    final actions = _actionsForRule(rule);
    if (actions.isEmpty) {
      errors.add('Rule "${rule.name}" must have at least one action.');
    }
    for (final action in actions) {
      errors.addAll(
        _ruleActionErrors(
          rule,
          action,
          variablesById: variablesById,
          objectIds: objectIds,
        ),
      );
    }
    return errors;
  }

  List<String> _ruleActionErrors(
    BuilderRule rule,
    Map<String, dynamic> action, {
    required Map<String, BuilderVariable> variablesById,
    required Set<String> objectIds,
  }) {
    final type = action['type']?.toString();
    switch (type) {
      case 'show_warning':
        final message = action['message']?.toString().trim() ?? '';
        return message.isEmpty
            ? ['Rule "${rule.name}" show_warning message cannot be empty.']
            : const [];
      case 'hide_object':
      case 'show_object':
        final objectId = action['objectId']?.toString();
        return objectId == null || !objectIds.contains(objectId)
            ? [
                'Rule "${rule.name}" action references missing object ${objectId ?? ''}.',
              ]
            : const [];
      case 'set_variable':
        final variableId = action['variableId']?.toString();
        return variableId == null || !variablesById.containsKey(variableId)
            ? [
                'Rule "${rule.name}" action references missing variable ${variableId ?? ''}.',
              ]
            : const [];
      case 'toggle_variable':
        final variableId = action['variableId']?.toString();
        final variable = variableId == null ? null : variablesById[variableId];
        if (variable == null) {
          return [
            'Rule "${rule.name}" action references missing variable ${variableId ?? ''}.',
          ];
        }
        final isBoolean =
            variable.defaultValue is bool || variable.type == 'toggle';
        return isBoolean
            ? const []
            : ['Rule "${rule.name}" toggle_variable requires a boolean variable.'];
      default:
        return ['Rule "${rule.name}" has unsupported action ${type ?? ''}.'];
    }
  }

  List<Map<String, dynamic>> _actionsForRule(BuilderRule rule) {
    final rawActions = rule.runtimeConfig['actions'];
    if (rawActions is List) {
      return rawActions
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList(growable: false);
    }
    return rule.action.isEmpty ? const [] : [rule.action];
  }

  List<List<String>> _dependencyCycles(dynamic variables) {
    final graph = <String, List<String>>{};
    for (final variable in variables) {
      final config = Map<String, dynamic>.from(variable.runtimeConfig as Map);
      final deps = _dependenciesFromConfig(variable.type.toString(), config);
      if (deps.isNotEmpty) {
        graph[variable.id.toString()] = deps;
      }
    }

    final cycles = <List<String>>[];
    final visiting = <String>{};
    final visited = <String>{};
    final stack = <String>[];

    void dfs(String node) {
      if (visiting.contains(node)) {
        final start = stack.indexOf(node);
        if (start >= 0) cycles.add([...stack.sublist(start), node]);
        return;
      }
      if (visited.contains(node)) return;
      visiting.add(node);
      stack.add(node);
      for (final next in graph[node] ?? const <String>[]) {
        if (graph.containsKey(next)) dfs(next);
      }
      stack.removeLast();
      visiting.remove(node);
      visited.add(node);
    }

    for (final node in graph.keys) {
      dfs(node);
    }
    return cycles;
  }

  List<String> _dependenciesFromConfig(
    String type,
    Map<String, dynamic> config,
  ) {
    switch (type) {
      case 'average':
      case 'minimum':
      case 'maximum':
        final value = config['dependencies'];
        if (value is List) {
          return value.map((entry) => entry.toString()).toList(growable: false);
        }
        return const [];
      case 'distance':
        return _dependencyIds(config, ['speedVariable', 'timeVariable']);
      case 'velocity':
        return _dependencyIds(config, ['distanceVariable', 'timeVariable']);
      case 'acceleration':
        return _dependencyIds(config, ['velocityVariable', 'timeVariable']);
      case 'force':
        return _dependencyIds(config, ['massVariable', 'accelerationVariable']);
      case 'power':
        return _dependencyIds(config, ['forceVariable', 'velocityVariable']);
      case 'energy':
        return _dependencyIds(config, ['powerVariable', 'timeVariable']);
      default:
        return const [];
    }
  }

  List<String> _dependencyIds(Map<String, dynamic> config, List<String> keys) {
    return keys
        .map((key) => config[key]?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _runtimeConfigErrors(
    BuilderObject object,
    Set<String> variableIds,
  ) {
    final config = Map<String, dynamic>.from(object.runtimeConfig);
    final errors = <String>[];
    num? number(String key) {
      final value = config[key];
      if (value is num) return value;
      return num.tryParse(value?.toString() ?? '');
    }

    bool exists(String? id) =>
        id != null && id.isNotEmpty && variableIds.contains(id);
    final name = object.name;
    switch (object.type) {
      case 'numericDisplay':
        final precision = number('precision');
        if (precision != null && precision < 0) {
          errors.add('Numeric Display "$name" precision must be >= 0.');
        }
        break;
      case 'gauge':
        final min = number('min');
        final max = number('max');
        final threshold = number('warningThreshold');
        if (min != null && max != null && min >= max) {
          errors.add('Gauge "$name" min must be less than max.');
        }
        if (min != null &&
            max != null &&
            threshold != null &&
            (threshold < min || threshold > max)) {
          errors.add('Gauge "$name" warning threshold must be inside range.');
        }
        break;
      case 'progressBar':
        final min = number('min');
        final max = number('max');
        if (min != null && max != null && min >= max) {
          errors.add('Progress Bar "$name" min must be less than max.');
        }
        break;
      case 'lineGraph':
        final variableId =
            config['variableId']?.toString() ??
            object.properties['linked_variable']?.toString();
        if (!exists(variableId)) {
          errors.add('Line Graph "$name" variable must exist.');
        }
        break;
      case 'scatterPlot':
        final xVariable = config['xVariable']?.toString();
        final yVariable = config['yVariable']?.toString();
        if (!exists(xVariable)) {
          errors.add('Scatter Plot "$name" X variable must exist.');
        }
        if (!exists(yVariable)) {
          errors.add('Scatter Plot "$name" Y variable must exist.');
        }
        if (exists(xVariable) && xVariable == yVariable) {
          errors.add('Scatter Plot "$name" X and Y variables must differ.');
        }
        break;
      case 'table':
        final maxRows = number('maxRows');
        if (maxRows != null && maxRows <= 0) {
          errors.add('Table "$name" maxRows must be greater than 0.');
        }
        break;
    }
    return errors;
  }
}
