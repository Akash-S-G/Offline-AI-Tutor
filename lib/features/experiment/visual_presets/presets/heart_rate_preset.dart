import '../models/visual_preset.dart';
import 'preset_helpers.dart';

VisualPreset heartRatePreset() {
  return simplePreset(
    id: 'heartRate',
    name: 'Heart Rate Preset',
    description: 'Heart, pulse ring, BPM display, and waveform.',
    supportedVariables: const ['heartRate.bpm'],
    actors: (context) => [
      presetActor(
        id: 'preset_heart_core',
        type: 'circle',
        x: 320,
        y: 135,
        state: {'radius': 34, 'color': '#ef4444'},
      ),
      presetActor(
        id: 'preset_heart_pulse_ring',
        type: 'circle',
        x: 320,
        y: 135,
        state: {'radius': 48, 'color': '#fecaca'},
        opacity: 0.55,
      ),
      presetActor(
        id: 'preset_heart_bpm',
        type: 'text',
        x: 320,
        y: 205,
        state: {'text': 'BPM', 'fontSize': 20, 'color': '#991b1b'},
      ),
      presetActor(
        id: 'preset_heart_waveform',
        type: 'line',
        x: 210,
        y: 250,
        state: {'width': 220, 'strokeWidth': 3, 'color': '#ef4444'},
      ),
    ],
    bindings: (context) {
      final bpm = context.variableFor('heartRate.bpm', fallback: 'var_pulse');
      return [
        if (bpm != null)
          binding(
            id: 'preset_heart_bpm_text',
            variableId: bpm,
            actorId: 'preset_heart_bpm',
            property: 'text',
          ),
        if (bpm != null)
          binding(
            id: 'preset_heart_ring_scale',
            variableId: bpm,
            actorId: 'preset_heart_pulse_ring',
            property: 'scale',
            transform: {
              'min': 40,
              'max': 180,
              'outputMin': 0.8,
              'outputMax': 1.35,
            },
          ),
      ];
    },
    animations: (context) => [
      animation(
        id: 'preset_heart_pulse',
        actorId: 'preset_heart_core',
        type: 'pulse',
        duration: 0.7,
        state: {'base': 1, 'amplitude': 0.13, 'frequency': 1.2},
      ),
    ],
  );
}
