import '../models/visual_preset.dart';
import 'preset_helpers.dart';

VisualPreset waterCyclePreset() {
  return simplePreset(
    id: 'waterCycle',
    name: 'Water Cycle Preset',
    description: 'Ocean, cloud, sun, rain, and water-cycle arrows.',
    supportedVariables: const ['waterCycle.temperature'],
    actors: (context) => [
      presetActor(
        id: 'preset_water_ocean',
        type: 'rectangle',
        x: 320,
        y: 260,
        state: {'width': 280, 'height': 45, 'color': '#0ea5e9'},
      ),
      presetActor(
        id: 'preset_water_cloud',
        type: 'circle',
        x: 310,
        y: 95,
        state: {'radius': 36, 'color': '#e2e8f0'},
      ),
      presetActor(
        id: 'preset_water_sun',
        type: 'circle',
        x: 455,
        y: 70,
        state: {'radius': 32, 'color': '#facc15'},
      ),
      presetActor(
        id: 'preset_water_rain',
        type: 'line',
        x: 305,
        y: 130,
        rotation: 1.5708,
        state: {'width': 70, 'strokeWidth': 3, 'color': '#38bdf8'},
      ),
      presetActor(
        id: 'preset_water_evap_arrow',
        type: 'arrow',
        x: 230,
        y: 220,
        rotation: -1.5708,
        state: {'width': 100, 'strokeWidth': 3, 'color': '#f97316'},
      ),
      presetActor(
        id: 'preset_water_cycle_label',
        type: 'text',
        x: 320,
        y: 25,
        state: {'text': 'Water Cycle', 'fontSize': 18},
      ),
    ],
    bindings: (context) {
      final temperature = context.variableFor(
        'waterCycle.temperature',
        fallback: 'var_temp',
      );
      return [
        if (temperature != null)
          binding(
            id: 'preset_water_evap_scale',
            variableId: temperature,
            actorId: 'preset_water_evap_arrow',
            property: 'scale',
            transform: {
              'min': 0,
              'max': 100,
              'outputMin': 0.65,
              'outputMax': 1.45,
            },
          ),
      ];
    },
    animations: (context) => [
      animation(
        id: 'preset_water_evaporation',
        actorId: 'preset_water_evap_arrow',
        type: 'pulse',
        duration: 1.8,
        state: {'base': 1, 'amplitude': 0.08, 'frequency': 0.5},
      ),
      animation(
        id: 'preset_water_rainfall',
        actorId: 'preset_water_rain',
        type: 'fade',
        duration: 1.2,
        state: {'from': 0.25, 'to': 1},
      ),
    ],
  );
}
