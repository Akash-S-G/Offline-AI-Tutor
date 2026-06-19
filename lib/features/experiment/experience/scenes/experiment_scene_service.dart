import 'dart:convert';
import 'package:flutter/services.dart';

import 'scene_definition_v3.dart';

class ExperimentSceneService {
  static const String _mappingPath = 'assets/experiment_scenes/experiment_scene_mapping.json';
  static const String _registryPath = 'assets/asset_registry.json';

  Map<String, String>? _mappingCache;
  Map<String, dynamic>? _registryCache;

  Future<void> initialize() async {
    try {
      final mappingString = await rootBundle.loadString(_mappingPath);
      _mappingCache = Map<String, String>.from(jsonDecode(mappingString));
      
      final registryString = await rootBundle.loadString(_registryPath);
      _registryCache = jsonDecode(registryString);
    } catch (e) {
      debugPrint('Failed to load scene registry or mapping: $e');
    }
  }

  SceneDefinitionV3 resolveScene(String experimentTitle, String defaultSceneId) {
    if (_mappingCache == null || _registryCache == null) {
      return SceneDefinitionV3(
        sceneId: defaultSceneId,
        backgroundAssets: [],
        actorAssets: [],
        effectAssets: [],
        theme: defaultSceneId,
      );
    }

    final sceneId = _mappingCache![experimentTitle] ?? defaultSceneId;
    final sceneData = _registryCache![sceneId] as Map<String, dynamic>?;

    if (sceneData == null) {
      return SceneDefinitionV3(
        sceneId: sceneId,
        backgroundAssets: [],
        actorAssets: [],
        effectAssets: [],
        theme: sceneId,
      );
    }

    final backgrounds = (sceneData['background'] as Map<String, dynamic>?)?.values.map((e) => e.toString()).toList() ?? [];
    final actors = (sceneData['actors'] as Map<String, dynamic>?)?.values.map((e) => e.toString()).toList() ?? [];
    final effects = (sceneData['effects'] as Map<String, dynamic>?)?.values.map((e) => e.toString()).toList() ?? [];

    return SceneDefinitionV3(
      sceneId: sceneId,
      backgroundAssets: backgrounds,
      actorAssets: actors,
      effectAssets: effects,
      theme: sceneId,
    );
  }
}

void debugPrint(String message) {
  // Simple print for debug
  print(message);
}
