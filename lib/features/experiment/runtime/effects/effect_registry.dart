import 'effect.dart';
import 'motion_trail_effect.dart';
import 'glow_effect.dart';
import 'ripple_effect.dart';
import 'pulse_ring_effect.dart';
import 'current_flow_effect.dart';
import 'rain_effect.dart';
import 'cloud_effect.dart';
import 'wave_motion_effect.dart';
import 'velocity_vector_effect.dart';
import 'water_droplets_effect.dart';
import 'organic_growth_effect.dart';

/// Central registry mapping effect type strings to [RuntimeEffect] instances.
/// Add new effects HERE only. No experiment-specific code anywhere else.
class EffectRegistry {
  static final Map<String, RuntimeEffect> _registry = {};

  static void initialize() {
    register(MotionTrailEffect());
    register(GlowEffect());
    register(RippleEffect());
    register(PulseRingEffect());
    register(CurrentFlowEffect());
    register(RainEffect());
    register(CloudEffect());
    register(WaveMotionEffect());
    register(VelocityVectorEffect());
    register(WaterDropletsEffect());
    register(OrganicGrowthEffect());
  }

  static void register(RuntimeEffect effect) {
    _registry[effect.type] = effect;
  }

  static RuntimeEffect? resolve(String type) => _registry[type];

  static bool supports(String type) => _registry.containsKey(type);

  static List<String> get registeredTypes => _registry.keys.toList();
}
