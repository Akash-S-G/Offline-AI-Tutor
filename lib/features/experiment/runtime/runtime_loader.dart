import 'runtime_world.dart';
import 'runtime_validator.dart';
import 'runtime_profiles.dart';
import 'runtime_object_factory.dart';

class RuntimeLoader {
  static RuntimeWorld loadFromManifest(Map<String, dynamic> manifest) {
    // 0. Register defaults
    if (RuntimeObjectFactory.availableCapabilities.isEmpty) {
      RuntimeObjectFactory.registerDefaults();
    }

    // 1. Validation
    RuntimeValidator.validate(manifest);

    // 2. Profile & Metadata Extraction
    final profile = RuntimeProfileManager.determineProfile(manifest);
    final metadata = manifest['metadata'] as Map<String, dynamic>? ?? {};

    // 3. Scene Extraction
    final sceneData = manifest['scene'] as Map<String, dynamic>? ?? {};
    final variablesJson = List<Map<String, dynamic>>.from(sceneData['variables'] ?? []);
    final objectsJson = List<Map<String, dynamic>>.from(sceneData['objects'] ?? []);
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
}

