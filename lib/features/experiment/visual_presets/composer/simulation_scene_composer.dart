import '../../blueprints/models/experiment_blueprint.dart';
import '../../runtime/runtime_event.dart';
import '../../runtime/runtime_event_bus.dart';
import '../../runtime/runtime_world.dart';
import '../models/preset_variable_mapping.dart';
import '../models/visual_preset_context.dart';
import '../models/visual_preset_scene.dart';
import '../registry/visual_preset_registry.dart';

class SimulationSceneComposer {
  final VisualPresetRegistry registry;
  final RuntimeEventBus eventBus;

  const SimulationSceneComposer({
    required this.registry,
    required this.eventBus,
  });

  VisualPresetScene? composeBlueprint(
    ExperimentBlueprint blueprint,
    RuntimeWorld world,
  ) {
    if (blueprint.visualPreset.isEmpty) return null;
    return composePresetById(
      blueprint.visualPreset,
      world,
      mappings: blueprint.parameters
          .map(
            (parameter) => PresetVariableMapping(
              variableId: parameter.variableId,
              presetPath: _presetPathFor(blueprint.visualPreset, parameter.id),
            ),
          )
          .toList(growable: false),
      metadata: {'blueprintId': blueprint.id},
    );
  }

  VisualPresetScene? composePresetById(
    String presetId,
    RuntimeWorld world, {
    List<PresetVariableMapping> mappings = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    final preset = registry.find(presetId);
    if (preset == null) {
      _emit(
        'PresetFailed',
        metadata: {'presetId': presetId, 'reason': 'Missing preset'},
      );
      return null;
    }
    try {
      final context = VisualPresetContext(
        world: world,
        mappings: mappings.isEmpty
            ? _defaultMappings(presetId, world)
            : mappings,
        metadata: metadata,
      );
      final scene = VisualPresetScene(
        presetId: preset.id,
        actors: preset.actorFactory(context),
        bindings: preset.bindingFactory(context),
        animations: preset.animationFactory(context),
      );
      for (final actor in scene.actors) {
        world.simulationCanvas.addActor(actor);
      }
      world.visualBindings.addBindings(scene.bindings);
      world.animationEngine.addAnimations(scene.animations);
      _emit(
        'PresetSceneBuilt',
        metadata: {
          'presetId': preset.id,
          'actorCount': scene.actors.length,
          'bindingCount': scene.bindings.length,
          'animationCount': scene.animations.length,
        },
      );
      return scene;
    } catch (error) {
      _emit(
        'PresetFailed',
        metadata: {'presetId': presetId, 'reason': error.toString()},
      );
      return null;
    }
  }

  List<PresetVariableMapping> _defaultMappings(
    String presetId,
    RuntimeWorld world,
  ) {
    final ids = world.variables.allRuntimeVariables.keys.toSet();
    String? firstExisting(List<String> candidates) {
      for (final candidate in candidates) {
        if (ids.contains(candidate)) return candidate;
      }
      return null;
    }

    switch (presetId) {
      case 'pendulum':
        return [
          if (firstExisting(['var_length']) != null)
            PresetVariableMapping(
              variableId: firstExisting(['var_length'])!,
              presetPath: 'pendulum.length',
            ),
          if (firstExisting(['var_angle']) != null)
            PresetVariableMapping(
              variableId: firstExisting(['var_angle'])!,
              presetPath: 'pendulum.angle',
            ),
        ];
      case 'freeFall':
        return [
          if (firstExisting(['var_height']) != null)
            PresetVariableMapping(
              variableId: firstExisting(['var_height'])!,
              presetPath: 'freeFall.height',
            ),
          if (firstExisting(['var_velocity', 'var_accel_1']) != null)
            PresetVariableMapping(
              variableId: firstExisting(['var_velocity', 'var_accel_1'])!,
              presetPath: 'freeFall.velocity',
            ),
        ];
      case 'heartRate':
        return [
          if (firstExisting(['var_pulse']) != null)
            PresetVariableMapping(
              variableId: firstExisting(['var_pulse'])!,
              presetPath: 'heartRate.bpm',
            ),
        ];
      case 'plantGrowth':
        return [
          if (firstExisting(['var_water']) != null)
            PresetVariableMapping(
              variableId: firstExisting(['var_water'])!,
              presetPath: 'plant.water',
            ),
          if (firstExisting(['var_sunlight']) != null)
            PresetVariableMapping(
              variableId: firstExisting(['var_sunlight'])!,
              presetPath: 'plant.sunlight',
            ),
        ];
      case 'waterCycle':
        return [
          if (firstExisting(['var_temp']) != null)
            PresetVariableMapping(
              variableId: firstExisting(['var_temp'])!,
              presetPath: 'waterCycle.temperature',
            ),
        ];
      default:
        return const [];
    }
  }

  String _presetPathFor(String presetId, String parameterId) {
    final compact = parameterId.replaceFirst('param_', '');
    switch (presetId) {
      case 'pendulum':
        return compact == 'angle' ? 'pendulum.angle' : 'pendulum.length';
      case 'freeFall':
        return compact == 'velocity' ? 'freeFall.velocity' : 'freeFall.height';
      case 'heartRate':
        return 'heartRate.bpm';
      case 'plantGrowth':
        return compact == 'sunlight' ? 'plant.sunlight' : 'plant.water';
      case 'waterCycle':
        return 'waterCycle.temperature';
      default:
        return '$presetId.$compact';
    }
  }

  void _emit(String message, {Map<String, dynamic>? metadata}) {
    eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: metadata,
      ),
    );
  }
}
