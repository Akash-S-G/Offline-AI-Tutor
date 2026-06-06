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
      objects: _mapObjects(sceneJson['objects'] as List?),
      variables: _mapVariables(sceneJson['variables'] as List?),
      rules: _mapRules(sceneJson['rules'] as List?),
      metadata: sceneJson['metadata'] as Map<String, dynamic>?,
    );
  }

  static List<PlaygroundObject> _mapObjects(List<dynamic>? objectsJson) {
    if (objectsJson == null) return [];
    return objectsJson.map((obj) {
      final map = obj as Map<String, dynamic>;
      return PlaygroundObject(
        objectId: map['objectId'] ?? '',
        objectType: map['objectType'] ?? '',
        name: map['name'] ?? '',
        properties: map['properties'] as Map<String, dynamic>? ?? {},
        state: map['state'] as Map<String, dynamic>? ?? {},
        metadata: map['metadata'] as Map<String, dynamic>?,
      );
    }).toList();
  }

  static List<PlaygroundVariable> _mapVariables(List<dynamic>? variablesJson) {
    if (variablesJson == null) return [];
    return variablesJson.map((varJson) {
      final map = varJson as Map<String, dynamic>;
      return PlaygroundVariable(
        name: map['name'] ?? '',
        type: map['type'] ?? 'number',
        value: map['value'],
        minValue: map['minValue'],
        maxValue: map['maxValue'],
        unit: map['unit'],
      );
    }).toList();
  }

  static List<PlaygroundRule> _mapRules(List<dynamic>? rulesJson) {
    if (rulesJson == null) return [];
    return rulesJson.map((ruleJson) {
      final map = ruleJson as Map<String, dynamic>;
      return PlaygroundRule(
        ruleId: map['ruleId'] ?? '',
        name: map['name'] ?? '',
        trigger: map['trigger'] ?? '',
        condition: map['condition'] as Map<String, dynamic>? ?? {},
        action: map['action'] as Map<String, dynamic>? ?? {},
        enabled: map['enabled'] ?? true,
      );
    }).toList();
  }
}
