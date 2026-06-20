import 'behavior.dart';
import 'oscillation_behavior.dart';
import 'flow_behavior.dart';
import 'pulse_behavior.dart';
import 'growth_behavior.dart';
import 'orbit_behavior.dart';

/// Central registry that maps behavior type strings to Behavior instances.
/// Add new behaviors HERE only. No experiment-specific code anywhere else.
class BehaviorRegistry {
  static final Map<String, Behavior> _registry = {};

  static void initialize() {
    register(OscillationBehavior());
    register(FlowBehavior());
    register(PulseBehavior());
    register(GrowthBehavior());
    register(OrbitBehavior());
  }

  static void register(Behavior behavior) {
    _registry[behavior.type] = behavior;
  }

  static Behavior? resolve(String type) => _registry[type];

  static bool supports(String type) => _registry.containsKey(type);

  static List<String> get registeredTypes => _registry.keys.toList();
}
