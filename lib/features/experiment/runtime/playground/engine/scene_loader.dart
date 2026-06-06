// ignore_for_file: avoid_print

import '../models/playground_scene.dart';
import '../models/playground_object.dart';
import '../models/playground_variable.dart';
import '../models/playground_rule.dart';

class SceneLoader {
  PlaygroundScene loadSceneFromJson(Map<String, dynamic> json) {
    try {
      final sceneId = json['sceneId'] as String;
      final name = json['name'] as String? ?? 'Untitled Scene';
      final description = json['description'] as String? ?? '';
      final metadata = json['metadata'] as Map<String, dynamic>?;

      final objects = (json['objects'] as List<dynamic>? ?? []).map((obj) {
        return PlaygroundObject(
          objectId: obj['objectId'],
          objectType: obj['objectType'],
          name: obj['name'] ?? obj['objectId'],
          properties: obj['properties'] ?? {},
          state: obj['state'] ?? {},
          metadata: obj['metadata'],
        );
      }).toList();

      final variables = (json['variables'] as List<dynamic>? ?? []).map((v) {
        return PlaygroundVariable(
          name: v['name'],
          type: v['type'],
          value: v['value'],
          minValue: v['minValue'],
          maxValue: v['maxValue'],
          unit: v['unit'],
        );
      }).toList();

      final rules = (json['rules'] as List<dynamic>? ?? []).map((r) {
        return PlaygroundRule(
          ruleId: r['ruleId'],
          name: r['name'] ?? r['ruleId'],
          trigger: r['trigger'],
          condition: r['condition'] ?? {},
          action: r['action'] ?? {},
          enabled: r['enabled'] ?? true,
        );
      }).toList();

      return PlaygroundScene(
        sceneId: sceneId,
        name: name,
        description: description,
        objects: objects,
        variables: variables,
        rules: rules,
        metadata: metadata,
      );
    } catch (e) {
      print('[PLAYGROUND] LOAD_ERROR message=$e');
      rethrow;
    }
  }
}
