import 'dart:math' as math;

import '../models/visual_preset.dart';
import 'preset_helpers.dart';

VisualPreset pendulumPreset() {
  return simplePreset(
    id: 'pendulum',
    name: 'Pendulum Preset',
    description: 'Anchor, rod, bob, angle indicator, and motion trail.',
    supportedVariables: const ['pendulum.length', 'pendulum.angle'],
    actors: (context) {
      return [
        presetActor(
          id: 'preset_pendulum_anchor',
          type: 'circle',
          x: 320,
          y: 80,
          state: {'radius': 10, 'color': '#334155'},
        ),
        presetActor(
          id: 'preset_pendulum_rod',
          type: 'line',
          x: 320,
          y: 80,
          rotation: math.pi / 4,
          state: {'width': 130, 'strokeWidth': 4, 'color': '#475569'},
        ),
        presetActor(
          id: 'preset_pendulum_bob',
          type: 'circle',
          x: 412,
          y: 172,
          state: {'radius': 24, 'color': '#0f766e'},
        ),
        presetActor(
          id: 'preset_pendulum_length_label',
          type: 'text',
          x: 235,
          y: 135,
          state: {'text': 'Length', 'fontSize': 14, 'color': '#334155'},
        ),
        presetActor(
          id: 'preset_pendulum_angle_indicator',
          type: 'arrow',
          x: 320,
          y: 80,
          rotation: math.pi / 4,
          state: {'width': 60, 'strokeWidth': 2, 'color': '#f59e0b'},
        ),
        presetActor(
          id: 'preset_pendulum_trail',
          type: 'line',
          x: 270,
          y: 200,
          state: {'width': 120, 'strokeWidth': 2, 'color': '#93c5fd'},
          opacity: 0.45,
        ),
      ];
    },
    bindings: (context) {
      final angle = context.variableFor(
        'pendulum.angle',
        fallback: 'var_angle',
      );
      final length = context.variableFor(
        'pendulum.length',
        fallback: 'var_length',
      );
      return [
        if (angle != null)
          binding(
            id: 'preset_pendulum_angle_rotation',
            variableId: angle,
            actorId: 'preset_pendulum_rod',
            property: 'rotation',
            transform: {
              'min': -90,
              'max': 90,
              'outputMin': -math.pi / 2,
              'outputMax': math.pi / 2,
            },
          ),
        if (angle != null)
          binding(
            id: 'preset_pendulum_indicator_rotation',
            variableId: angle,
            actorId: 'preset_pendulum_angle_indicator',
            property: 'rotation',
            transform: {
              'min': -90,
              'max': 90,
              'outputMin': -math.pi / 2,
              'outputMax': math.pi / 2,
            },
          ),
        if (length != null)
          binding(
            id: 'preset_pendulum_length_width',
            variableId: length,
            actorId: 'preset_pendulum_rod',
            property: 'width',
            transform: {
              'min': 0.5,
              'max': 5,
              'outputMin': 70,
              'outputMax': 190,
            },
          ),
      ];
    },
    animations: (context) => [
      animation(
        id: 'preset_pendulum_swing',
        actorId: 'preset_pendulum_rod',
        type: 'oscillate',
        duration: 2,
        state: {
          'property': 'rotation',
          'base': 0,
          'amplitude': 0.35,
          'frequency': 0.4,
        },
      ),
      animation(
        id: 'preset_pendulum_trail_pulse',
        actorId: 'preset_pendulum_trail',
        type: 'fade',
        duration: 1.4,
        state: {'from': 0.2, 'to': 0.6},
      ),
    ],
  );
}
