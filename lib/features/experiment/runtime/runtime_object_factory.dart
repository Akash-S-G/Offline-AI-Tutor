import 'package:flame/components.dart';
import 'engine/display_object_components.dart';
import 'engine/flame_object_components.dart';
import 'engine/interactive_object_components.dart';
import 'runtime_world.dart';

class ObjectCapabilityDefinition {
  final String type;
  final String description;
  final List<String> supportedProperties;
  final List<String> supportedActions;
  final List<String> supportedEvents;
  final Component Function(Map<String, dynamic> data, RuntimeWorld world)
  builder;

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
    register(
      ObjectCapabilityDefinition(
        type: 'numericDisplay',
        description: 'Display object that renders formatted numeric values.',
        supportedProperties: ['value', 'label', 'unit', 'precision'],
        supportedActions: ['show_object', 'hide_object'],
        supportedEvents: [],
        builder: (data, world) => RuntimeDisplayObjectComponent(data, world),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'textDisplay',
        description: 'Display object that renders runtime text state.',
        supportedProperties: ['text', 'formattedText', 'value', 'label'],
        supportedActions: ['show_object', 'hide_object'],
        supportedEvents: [],
        builder: (data, world) => RuntimeDisplayObjectComponent(data, world),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'gauge',
        description: 'Display object that renders a normalized gauge.',
        supportedProperties: [
          'value',
          'min',
          'max',
          'normalizedValue',
          'warningThreshold',
          'unit',
        ],
        supportedActions: ['show_object', 'hide_object'],
        supportedEvents: [],
        builder: (data, world) => RuntimeDisplayObjectComponent(data, world),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'progressBar',
        description: 'Display object that renders normalized progress.',
        supportedProperties: ['value', 'min', 'max', 'normalizedValue'],
        supportedActions: ['show_object', 'hide_object'],
        supportedEvents: [],
        builder: (data, world) => RuntimeDisplayObjectComponent(data, world),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'lineGraph',
        description: 'Live line graph that renders measurement history.',
        supportedProperties: ['linked_variable', 'linkedVariable'],
        supportedActions: ['show_object', 'hide_object'],
        supportedEvents: [],
        builder: (data, world) => RuntimeDisplayObjectComponent(data, world),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'table',
        description: 'Observation table that renders recorded lab rows.',
        supportedProperties: ['columns', 'rows'],
        supportedActions: ['show_object', 'hide_object'],
        supportedEvents: [],
        builder: (data, world) => RuntimeDisplayObjectComponent(data, world),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'button',
        description:
            'Interactive button that writes press state to a variable.',
        supportedProperties: ['linked_variable'],
        supportedActions: [],
        supportedEvents: ['buttonPressed', 'buttonReleased'],
        builder: (data, world) => RuntimeButtonComponent(data, world),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'slider',
        description:
            'Interactive slider that writes numeric values to a variable.',
        supportedProperties: ['linked_variable'],
        supportedActions: [],
        supportedEvents: ['sliderChanged'],
        builder: (data, world) => RuntimeSliderComponent(data, world),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'toggle',
        description:
            'Interactive toggle that writes boolean values to a variable.',
        supportedProperties: ['linked_variable'],
        supportedActions: [],
        supportedEvents: ['toggleEnabled', 'toggleDisabled'],
        builder: (data, world) => RuntimeToggleComponent(data, world),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'physics_ball',
        description:
            'A dynamic physics ball affected by gravity and collisions.',
        supportedProperties: ['restitution', 'density', 'friction'],
        supportedActions: ['applyForce', 'applyImpulse'],
        supportedEvents: ['onCollision', 'onTap'],
        builder: (data, world) =>
            PhysicsBall(initialPosition: Vector2(100, 100)),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'pendulumSimulation',
        description: 'A pendulum that simulates harmonic motion.',
        supportedProperties: ['linked_variable'],
        supportedActions: ['reset'],
        supportedEvents: [],
        builder: (data, world) => BuilderObjectComponent(data, world),
      ),
    );

    register(
      ObjectCapabilityDefinition(
        type: 'plantSimulation',
        description:
            'A biology plant simulation that responds to water and sunlight.',
        supportedProperties: ['water_var', 'sun_var'],
        supportedActions: ['reset'],
        supportedEvents: ['onGrowthStageChanged'],
        builder: (data, world) => BuilderObjectComponent(data, world),
      ),
    );

    // Register basic shapes for future use
    register(
      ObjectCapabilityDefinition(
        type: 'circle',
        description: 'A basic circle primitive.',
        supportedProperties: ['radius', 'color'],
        supportedActions: [],
        supportedEvents: ['onTap'],
        builder: (data, world) => BuilderObjectComponent(data, world),
      ),
    );
  }

  static Component create(Map<String, dynamic> data, RuntimeWorld world) {
    final type = data['objectType'] as String? ?? 'unknown';
    if (_registry.containsKey(type)) {
      return _registry[type]!.builder(data, world);
    }
    // Fallback default component
    return BuilderObjectComponent(data, world);
  }

  static List<ObjectCapabilityDefinition> get availableCapabilities =>
      _registry.values.toList();
}
