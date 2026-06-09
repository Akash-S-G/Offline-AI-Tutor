import '../runtime/playground/models/playground_scene.dart';
import '../runtime/playground/models/playground_object.dart';
import '../runtime/playground/models/playground_variable.dart';
import '../runtime/playground/models/playground_rule.dart';

class ExecutionDefinitionMapper {
  static PlaygroundScene mapToScene(Map<String, dynamic> json) {
    final sceneJson = json['scene'] as Map<String, dynamic>? ?? {};

    return PlaygroundScene(
      sceneId: sceneJson['sceneId'] ?? 'unknown_scene',
      name: sceneJson['name'] ?? 'Unnamed Scene',
      description: sceneJson['description'] ?? '',
      objects: mapObjects(sceneJson['objects'] as List?),
      variables: mapVariables(sceneJson['variables'] as List?),
      rules: mapRules(sceneJson['rules'] as List?),
      metadata: sceneJson['metadata'] as Map<String, dynamic>?,
    );
  }

  static List<PlaygroundObject> mapObjects(List<dynamic>? objectsJson) {
    if (objectsJson == null) return [];
    return objectsJson
        .map((obj) => mapObject(obj as Map<String, dynamic>))
        .toList();
  }

  static PlaygroundObject mapObject(Map<String, dynamic> map) {
    return PlaygroundObject(
      objectId: map['objectId'] ?? '',
      objectType: map['objectType'] ?? '',
      name: map['name'] ?? '',
      properties: map['properties'] as Map<String, dynamic>? ?? {},
      state: map['state'] as Map<String, dynamic>? ?? {},
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  static List<PlaygroundVariable> mapVariables(List<dynamic>? variablesJson) {
    if (variablesJson == null) return [];
    return variablesJson
        .map((varJson) => mapVariable(varJson as Map<String, dynamic>))
        .toList();
  }

  static PlaygroundVariable mapVariable(Map<String, dynamic> map) {
    return PlaygroundVariable(
      id: map['id'] ?? map['name'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'number',
      value: map['value'],
      minValue: map['minValue'],
      maxValue: map['maxValue'],
      unit: map['unit'],
    );
  }

  static List<PlaygroundRule> mapRules(List<dynamic>? rulesJson) {
    if (rulesJson == null) return [];
    return rulesJson
        .map((ruleJson) => mapRule(ruleJson as Map<String, dynamic>))
        .toList();
  }

  static PlaygroundRule mapRule(Map<String, dynamic> map) {
    return PlaygroundRule(
      ruleId: map['ruleId'] ?? '',
      name: map['name'] ?? '',
      trigger: map['trigger'] ?? '',
      condition: map['condition'] as Map<String, dynamic>? ?? {},
      action: map['action'] as Map<String, dynamic>? ?? {},
      enabled: map['enabled'] ?? true,
    );
  }
}
