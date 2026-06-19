import 'runtime_world.dart';
import 'runtime_validator.dart';
import 'runtime_profiles.dart';
import 'runtime_object_factory.dart';

class RuntimeLoader {
  static RuntimeWorld loadFromManifest(Map<String, dynamic> manifest) {
    final normalizedManifest = _normalizeManifest(manifest);

    // 0. Register defaults
    RuntimeObjectFactory.registerDefaults();

    // 1. Validation
    RuntimeValidator.validate(normalizedManifest);

    // 2. Profile & Metadata Extraction
    final profile = RuntimeProfileManager.determineProfile(normalizedManifest);
    final manifestMetadata =
        normalizedManifest['metadata'] as Map<String, dynamic>? ?? {};

    // 3. Scene Extraction
    final sceneData =
        normalizedManifest['scene'] as Map<String, dynamic>? ?? {};
    final metadata = {
      ...manifestMetadata,
      if (sceneData['sceneId'] != null) 'sceneId': sceneData['sceneId'],
      if (sceneData['name'] != null) 'name': sceneData['name'],
      if (sceneData['description'] != null)
        'description': sceneData['description'],
      if (sceneData['objective'] != null) 'objective': sceneData['objective'],
      if (sceneData['experience'] != null)
        'experience': sceneData['experience'],
      if (sceneData['mission'] != null) 'mission': sceneData['mission'],
      if (sceneData['investigation'] != null)
        'investigation': sceneData['investigation'],
      if (sceneData['assessment'] != null)
        'assessment': sceneData['assessment'],
      if (sceneData['learningOutcomes'] != null)
        'learningOutcomes': sceneData['learningOutcomes'],
      if (sceneData['visualPreset'] != null)
        'visualPreset': sceneData['visualPreset'],
      if (sceneData['actors'] != null) 'actors': sceneData['actors'],
      if (sceneData['simulationActors'] != null)
        'simulationActors': sceneData['simulationActors'],
      if (sceneData['visualBindings'] != null)
        'visualBindings': sceneData['visualBindings'],
      if (sceneData['animations'] != null)
        'animations': sceneData['animations'],
    };
    metadata['visualPreset'] ??= _inferVisualPreset(
      sceneData,
      manifestMetadata,
    );
    final variablesJson = List<Map<String, dynamic>>.from(
      sceneData['variables'] ?? [],
    );
    final objectsJson = List<Map<String, dynamic>>.from(
      sceneData['objects'] ?? [],
    );
    final rulesJson = List<Map<String, dynamic>>.from(sceneData['rules'] ?? []);

    // 4. World Initialization
    final world = RuntimeWorld();
    world.initialize(
      variablesJson: variablesJson,
      objectsJson: objectsJson,
      rulesJson: rulesJson,
      runtimeProfile: profile,
      curriculumMetadata: metadata,
    );

    return world;
  }

  static Map<String, dynamic> _normalizeManifest(
    Map<String, dynamic> manifest,
  ) {
    if (manifest['scene'] is Map<String, dynamic>) return manifest;
    final hasSceneFields =
        manifest.containsKey('variables') ||
        manifest.containsKey('objects') ||
        manifest.containsKey('rules');
    if (!hasSceneFields) return manifest;
    return {
      'metadata': manifest['metadata'] as Map<String, dynamic>? ?? const {},
      'scene': {
        if (manifest['sceneId'] != null) 'sceneId': manifest['sceneId'],
        if (manifest['name'] != null) 'name': manifest['name'],
        if (manifest['description'] != null)
          'description': manifest['description'],
        if (manifest['tags'] != null) 'tags': manifest['tags'],
        'variables': manifest['variables'] ?? const [],
        'objects': manifest['objects'] ?? const [],
        'rules': manifest['rules'] ?? const [],
      },
    };
  }

  static String? _inferVisualPreset(
    Map<String, dynamic> sceneData,
    Map<String, dynamic> metadata,
  ) {
    final text =
        [
              sceneData['visualPreset'],
              sceneData['sceneId'],
              sceneData['name'],
              sceneData['description'],
              metadata['visualPreset'],
              metadata['category'],
              metadata['subject'],
            ]
            .whereType<Object>()
            .map((value) => value.toString().toLowerCase())
            .join(' ');
    if (text.contains('pendulum')) return 'pendulum';
    if (text.contains('free_fall') ||
        text.contains('free fall') ||
        text.contains('gravity')) {
      return 'freeFall';
    }
    if (text.contains('heart') || text.contains('pulse')) return 'heartRate';
    if (text.contains('plant') || text.contains('growth')) return 'plantGrowth';
    if (text.contains('water_cycle') || text.contains('water cycle')) {
      return 'waterCycle';
    }
    return null;
  }
}
