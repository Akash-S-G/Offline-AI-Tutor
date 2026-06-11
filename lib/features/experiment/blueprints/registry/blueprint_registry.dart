import '../models/experiment_blueprint.dart';

class BlueprintRegistry {
  final Map<String, ExperimentBlueprint> _blueprints = {};

  void registerBlueprint(ExperimentBlueprint blueprint) {
    if (blueprint.id.isEmpty) return;
    _blueprints[blueprint.id] = blueprint;
  }

  void removeBlueprint(String id) {
    _blueprints.remove(id);
  }

  ExperimentBlueprint? findBlueprint(String id) => _blueprints[id];

  List<ExperimentBlueprint> allBlueprints() {
    return _blueprints.values.toList(growable: false);
  }
}
