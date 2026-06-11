import '../../blueprints/models/experiment_blueprint.dart';
import '../../runtime/runtime_world.dart';
import 'preset_variable_mapping.dart';

class VisualPresetContext {
  final RuntimeWorld world;
  final ExperimentBlueprint? blueprint;
  final List<PresetVariableMapping> mappings;
  final Map<String, dynamic> metadata;

  const VisualPresetContext({
    required this.world,
    this.blueprint,
    this.mappings = const [],
    this.metadata = const {},
  });

  String? variableFor(String presetPath, {String? fallback}) {
    for (final mapping in mappings) {
      if (mapping.presetPath == presetPath) return mapping.variableId;
    }
    if (fallback != null && world.variables.containsVariable(fallback)) {
      return fallback;
    }
    return null;
  }
}
