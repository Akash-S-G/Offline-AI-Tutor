import '../models/experiment_blueprint.dart';
import '../models/experiment_parameter.dart';

class BlueprintRuntimeConverter {
  Map<String, dynamic> toManifest(
    ExperimentBlueprint blueprint, {
    Map<String, dynamic> parameterValues = const {},
  }) {
    final manifest = _deepCopy(blueprint.manifest);
    final metadata = Map<String, dynamic>.from(
      manifest['metadata'] as Map? ?? const {},
    );
    metadata['blueprintId'] = blueprint.id;
    if (blueprint.visualPreset.isNotEmpty) {
      metadata['visualPreset'] = blueprint.visualPreset;
    }
    if (blueprint.mission != null) {
      metadata['mission'] = blueprint.mission!.toJson();
    }
    if (blueprint.investigation.isNotEmpty) {
      metadata['investigation'] = blueprint.investigation;
    }
    if (blueprint.assessment != null) {
      metadata['assessment'] = blueprint.assessment!.toJson();
    }
    if (blueprint.learningOutcomes.isNotEmpty) {
      metadata['learningOutcomes'] = blueprint.learningOutcomes
          .map((outcome) => outcome.toJson())
          .toList();
    }
    metadata['experience'] = _experienceFor(blueprint);
    manifest['metadata'] = metadata;
    final scene = Map<String, dynamic>.from(
      manifest['scene'] as Map? ?? const {},
    );
    scene['experience'] = metadata['experience'];
    if (metadata['mission'] != null) {
      scene['mission'] = metadata['mission'];
    }
    if (metadata['investigation'] != null) {
      scene['investigation'] = metadata['investigation'];
    }
    if (metadata['assessment'] != null) {
      scene['assessment'] = metadata['assessment'];
    }
    if (metadata['learningOutcomes'] != null) {
      scene['learningOutcomes'] = metadata['learningOutcomes'];
    }
    final variables = (scene['variables'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    for (final parameter in blueprint.parameters) {
      _applyParameter(variables, parameter, parameterValues[parameter.id]);
    }
    scene['variables'] = variables;
    scene['objects'] = _objectsForParameters(
      List<Map<String, dynamic>>.from(scene['objects'] ?? const []),
      blueprint.parameters,
      parameterValues,
    );
    scene['metadata'] = {
      ...Map<String, dynamic>.from(scene['metadata'] as Map? ?? const {}),
      'observationTemplate': blueprint.observationTemplate.toJson(),
    };
    manifest['scene'] = scene;
    return manifest;
  }

  Map<String, dynamic> _experienceFor(ExperimentBlueprint blueprint) {
    return {
      'id': blueprint.id,
      'title': blueprint.name,
      'description': blueprint.description,
      'objective': blueprint.objectives.isEmpty
          ? blueprint.description
          : blueprint.objectives.first.description,
      'steps': [
        {
          'id': 'read_objective',
          'title': 'Experiment Goal',
          'instruction': blueprint.objectives.isEmpty
              ? 'Read the experiment goal.'
              : blueprint.objectives.first.description,
          'type': 'instruction',
          'completionCondition': {
            'type': 'custom',
            'eventName': 'ExperimentStarted',
          },
        },
        if (blueprint.parameters.isNotEmpty)
          {
            'id': 'adjust_parameter',
            'title': 'Adjust Parameters',
            'instruction': 'Change one parameter and observe the simulation.',
            'type': 'interaction',
            'completionCondition': {'type': 'controlUsed'},
          },
        {
          'id': 'record_observation',
          'title': 'Record Observations',
          'instruction': 'Record observations in the table.',
          'type': 'observation',
          'completionCondition': {'type': 'observation'},
        },
        if (blueprint.questions.isNotEmpty)
          {
            'id': 'answer_question',
            'title': 'Answer Question',
            'instruction': blueprint.questions.first.question,
            'type': 'question',
            'completionCondition': {'type': 'questionAnswered'},
          },
      ],
      'questions': blueprint.questions
          .map((question) => question.toJson())
          .toList(),
      'completionCriteria': [
        {
          'type': 'observations',
          'requiredRows': blueprint.observationTemplate.requiredRows,
        },
      ],
    };
  }

  void _applyParameter(
    List<Map<String, dynamic>> variables,
    ExperimentParameter parameter,
    dynamic value,
  ) {
    final nextValue = value ?? parameter.defaultValue;
    final index = variables.indexWhere((variable) {
      return variable['id']?.toString() == parameter.variableId;
    });
    if (index >= 0) {
      variables[index] = {
        ...variables[index],
        'value': nextValue,
        'runtimeConfig': {
          ...Map<String, dynamic>.from(
            variables[index]['runtimeConfig'] as Map? ?? const {},
          ),
          'displayName': parameter.displayName,
          'unit': parameter.unit,
          'minValue': parameter.minValue,
          'maxValue': parameter.maxValue,
          'defaultValue': parameter.defaultValue,
        },
      };
    }
  }

  List<Map<String, dynamic>> _objectsForParameters(
    List<Map<String, dynamic>> existing,
    List<ExperimentParameter> parameters,
    Map<String, dynamic> parameterValues,
  ) {
    final objects = [...existing];
    for (final parameter in parameters) {
      final objectId = 'control_${parameter.id}';
      if (objects.any(
        (object) => object['id'] == objectId || object['objectId'] == objectId,
      )) {
        continue;
      }
      objects.add({
        'id': objectId,
        'objectId': objectId,
        'type': parameter.controlType,
        'objectType': parameter.controlType,
        'name': parameter.displayName,
        'runtimeConfig': {
          'label': parameter.displayName,
          'variableId': parameter.variableId,
          'min': parameter.minValue,
          'max': parameter.maxValue,
          'unit': parameter.unit,
        },
        'state': {
          'label': parameter.displayName,
          'value': parameterValues[parameter.id] ?? parameter.defaultValue,
          'min': parameter.minValue,
          'max': parameter.maxValue,
          'unit': parameter.unit,
        },
      });
    }
    return objects;
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return Map<String, dynamic>.from(
      source.map((key, value) {
        if (value is Map) {
          return MapEntry(key, _deepCopy(Map<String, dynamic>.from(value)));
        }
        if (value is List) {
          return MapEntry(
            key,
            value.map((item) {
              if (item is Map) {
                return _deepCopy(Map<String, dynamic>.from(item));
              }
              return item;
            }).toList(),
          );
        }
        return MapEntry(key, value);
      }),
    );
  }
}
