import '../models/experiment_blueprint.dart';
import '../registry/blueprint_registry.dart';
import '../registry/built_in_blueprints.dart';

class BlueprintLoader {
  BlueprintRegistry loadBuiltIns() {
    final registry = BlueprintRegistry();
    for (final blueprint in BuiltInBlueprints.all()) {
      registry.registerBlueprint(blueprint);
    }
    return registry;
  }

  ExperimentBlueprint fromJson(Map<String, dynamic> json) {
    return ExperimentBlueprint.fromJson(json);
  }
}
