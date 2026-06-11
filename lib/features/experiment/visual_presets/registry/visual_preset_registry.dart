import '../models/visual_preset.dart';
import '../presets/free_fall_preset.dart';
import '../presets/heart_rate_preset.dart';
import '../presets/pendulum_preset.dart';
import '../presets/plant_growth_preset.dart';
import '../presets/water_cycle_preset.dart';

class VisualPresetRegistry {
  final Map<String, VisualPreset> _presets = {};

  VisualPresetRegistry() {
    registerDefaults();
  }

  void register(VisualPreset preset) {
    if (preset.id.isEmpty) return;
    _presets[preset.id] = preset;
  }

  VisualPreset? find(String id) => _presets[id];

  List<VisualPreset> allPresets() => _presets.values.toList(growable: false);

  void registerDefaults() {
    register(pendulumPreset());
    register(freeFallPreset());
    register(heartRatePreset());
    register(waterCyclePreset());
    register(plantGrowthPreset());
  }
}
