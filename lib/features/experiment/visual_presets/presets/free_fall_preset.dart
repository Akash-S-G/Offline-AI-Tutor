import '../models/visual_preset.dart';
import 'preset_helpers.dart';

VisualPreset freeFallPreset() {
  return simplePreset(
    id: 'freeFall',
    name: 'Free Fall Preset',
    description:
        'Falling object, ground, height marker, and velocity indicator.',
    supportedVariables: const ['freeFall.height', 'freeFall.velocity'],
    actors: (context) => [
      presetActor(
        id: 'preset_free_fall_ground',
        type: 'rectangle',
        x: 330,
        y: 260,
        state: {'width': 260, 'height': 12, 'color': '#475569'},
      ),
      presetActor(
        id: 'preset_free_fall_object',
        type: 'circle',
        x: 330,
        y: 90,
        state: {'radius': 22, 'color': '#2563eb'},
      ),
      presetActor(
        id: 'preset_free_fall_height_marker',
        type: 'line',
        x: 220,
        y: 80,
        rotation: 1.5708,
        state: {'width': 175, 'strokeWidth': 2, 'color': '#f97316'},
      ),
      presetActor(
        id: 'preset_free_fall_velocity',
        type: 'arrow',
        x: 370,
        y: 110,
        rotation: 1.5708,
        state: {'width': 55, 'strokeWidth': 4, 'color': '#dc2626'},
      ),
      presetActor(
        id: 'preset_free_fall_distance_label',
        type: 'text',
        x: 220,
        y: 60,
        state: {'text': 'Height', 'fontSize': 14},
      ),
    ],
    bindings: (context) {
      final height = context.variableFor(
        'freeFall.height',
        fallback: 'var_height',
      );
      final velocity = context.variableFor(
        'freeFall.velocity',
        fallback: 'var_velocity',
      );
      return [
        if (height != null)
          binding(
            id: 'preset_free_fall_height_y',
            variableId: height,
            actorId: 'preset_free_fall_object',
            property: 'positionY',
            transform: {
              'min': 0,
              'max': 100,
              'outputMin': 250,
              'outputMax': 70,
            },
          ),
        if (velocity != null)
          binding(
            id: 'preset_free_fall_velocity_width',
            variableId: velocity,
            actorId: 'preset_free_fall_velocity',
            property: 'width',
            transform: {'min': 0, 'max': 50, 'outputMin': 20, 'outputMax': 110},
          ),
      ];
    },
    animations: (context) => [
      animation(
        id: 'preset_free_fall_falling_motion',
        actorId: 'preset_free_fall_object',
        type: 'pulse',
        duration: 1.1,
        state: {'base': 1, 'amplitude': 0.06, 'frequency': 1.5},
      ),
    ],
  );
}
