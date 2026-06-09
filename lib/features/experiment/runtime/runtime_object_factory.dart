import 'package:flame/components.dart';
import 'engine/flame_object_components.dart';
import 'runtime_world.dart';

class ObjectCapabilityDefinition {
  final String type;
  final String description;
  final List<String> supportedProperties;
  final List<String> supportedActions;
  final List<String> supportedEvents;
  final Component Function(Map<String, dynamic> data, RuntimeWorld world) builder;

  ObjectCapabilityDefinition({
    required this.type,
    required this.description,
    required this.supportedProperties,
    required this.supportedActions,
    required this.supportedEvents,
    required this.builder,
  });
}

class RuntimeObjectFactory {
  static final Map<String, ObjectCapabilityDefinition> _registry = {};

  static void register(ObjectCapabilityDefinition definition) {
    _registry[definition.type] = definition;
  }

  static void registerDefaults() {
    register(ObjectCapabilityDefinition(
      type: 'physics_ball',
      description: 'A dynamic physics ball affected by gravity and collisions.',
      supportedProperties: ['restitution', 'density', 'friction'],
      supportedActions: ['applyForce', 'applyImpulse'],
      supportedEvents: ['onCollision', 'onTap'],
      builder: (data, world) => PhysicsBall(initialPosition: Vector2(100, 100)),
    ));
    
    register(ObjectCapabilityDefinition(
      type: 'pendulumSimulation',
      description: 'A pendulum that simulates harmonic motion.',
      supportedProperties: ['linked_variable'],
      supportedActions: ['reset'],
      supportedEvents: [],
      builder: (data, world) => BuilderObjectComponent(data, world),
    ));

    register(ObjectCapabilityDefinition(
      type: 'plantSimulation',
      description: 'A biology plant simulation that responds to water and sunlight.',
      supportedProperties: ['water_var', 'sun_var'],
      supportedActions: ['reset'],
      supportedEvents: ['onGrowthStageChanged'],
      builder: (data, world) => BuilderObjectComponent(data, world),
    ));

    // Register basic shapes for future use
    register(ObjectCapabilityDefinition(
      type: 'circle',
      description: 'A basic circle primitive.',
      supportedProperties: ['radius', 'color'],
      supportedActions: [],
      supportedEvents: ['onTap'],
      builder: (data, world) => BuilderObjectComponent(data, world),
    ));
  }

  static Component create(Map<String, dynamic> data, RuntimeWorld world) {
    final type = data['objectType'] as String? ?? 'unknown';
    if (_registry.containsKey(type)) {
      return _registry[type]!.builder(data, world);
    }
    // Fallback default component
    return BuilderObjectComponent(data, world);
  }

  static List<ObjectCapabilityDefinition> get availableCapabilities => _registry.values.toList();
}

