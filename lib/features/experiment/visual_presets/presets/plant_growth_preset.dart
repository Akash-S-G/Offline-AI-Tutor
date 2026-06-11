import '../models/visual_preset.dart';
import 'preset_helpers.dart';

VisualPreset plantGrowthPreset() {
  return simplePreset(
    id: 'plantGrowth',
    name: 'Plant Growth Preset',
    description: 'Pot, stem, leaves, water meter, and sunlight meter.',
    supportedVariables: const ['plant.water', 'plant.sunlight'],
    actors: (context) => [
      presetActor(
        id: 'preset_plant_pot',
        type: 'rectangle',
        x: 320,
        y: 245,
        state: {'width': 100, 'height': 45, 'color': '#92400e'},
      ),
      presetActor(
        id: 'preset_plant_stem',
        type: 'rectangle',
        x: 320,
        y: 180,
        state: {'width': 14, 'height': 110, 'color': '#15803d'},
      ),
      presetActor(
        id: 'preset_plant_leaf_left',
        type: 'circle',
        x: 285,
        y: 155,
        state: {'radius': 25, 'color': '#22c55e'},
      ),
      presetActor(
        id: 'preset_plant_leaf_right',
        type: 'circle',
        x: 355,
        y: 155,
        state: {'radius': 25, 'color': '#16a34a'},
      ),
      presetActor(
        id: 'preset_plant_water_meter',
        type: 'rectangle',
        x: 210,
        y: 235,
        state: {'width': 22, 'height': 70, 'color': '#38bdf8'},
      ),
      presetActor(
        id: 'preset_plant_sun_meter',
        type: 'circle',
        x: 440,
        y: 80,
        state: {'radius': 30, 'color': '#facc15'},
      ),
    ],
    bindings: (context) {
      final water = context.variableFor('plant.water', fallback: 'var_water');
      final sunlight = context.variableFor(
        'plant.sunlight',
        fallback: 'var_sunlight',
      );
      return [
        if (water != null)
          binding(
            id: 'preset_plant_water_scale',
            variableId: water,
            actorId: 'preset_plant_stem',
            property: 'scale',
            transform: {
              'min': 0,
              'max': 100,
              'outputMin': 0.55,
              'outputMax': 1.35,
            },
          ),
        if (water != null)
          binding(
            id: 'preset_plant_water_meter_height',
            variableId: water,
            actorId: 'preset_plant_water_meter',
            property: 'height',
            transform: {'min': 0, 'max': 100, 'outputMin': 10, 'outputMax': 90},
          ),
        if (sunlight != null)
          binding(
            id: 'preset_plant_sun_scale',
            variableId: sunlight,
            actorId: 'preset_plant_sun_meter',
            property: 'scale',
            transform: {
              'min': 0,
              'max': 100,
              'outputMin': 0.7,
              'outputMax': 1.4,
            },
          ),
      ];
    },
    animations: (context) => [
      animation(
        id: 'preset_plant_leaf_pulse',
        actorId: 'preset_plant_leaf_left',
        type: 'pulse',
        duration: 2.2,
        state: {'base': 1, 'amplitude': 0.05, 'frequency': 0.3},
      ),
    ],
  );
}
