import 'variable_store.dart';
import 'object_registry.dart';
import 'rule_engine.dart';
import 'runtime_event_bus.dart';
import 'simulation_clock.dart';
import 'runtime_analytics.dart';
import 'runtime_profiles.dart';

class RuntimeWorld {
  final VariableStore variables;
  final ObjectRegistry objects;
  late final RuleEngine rules;
  final RuntimeEventBus eventBus;
  final SimulationClock clock;
  final RuntimeAnalytics analytics;

  RuntimeProfile profile = RuntimeProfile.general;
  Map<String, dynamic> metadata = {};

  RuntimeWorld()
      : variables = VariableStore(),
        objects = ObjectRegistry(),
        eventBus = RuntimeEventBus(),
        clock = SimulationClock(),
        analytics = RuntimeAnalytics() {
    rules = RuleEngine(variables, eventBus);
    analytics.attach(eventBus);
  }

  void initialize({
    required List<Map<String, dynamic>> variablesJson,
    required List<Map<String, dynamic>> objectsJson,
    required List<Map<String, dynamic>> rulesJson,
    required RuntimeProfile runtimeProfile,
    required Map<String, dynamic> curriculumMetadata,
  }) {
    profile = runtimeProfile;
    metadata = curriculumMetadata;
    variables.initialize(variablesJson);
    objects.initialize(objectsJson);
    rules.initialize(rulesJson);
    clock.reset();
    analytics.recordLaunch();
  }

  void tick(double dt) {
    if (clock.isRunning) {
      clock.tick(dt);
      analytics.addTimeSpent(dt);
      rules.evaluateContinuousRules(dt);
    }
  }

  void dispose() {
    analytics.dispose();
    eventBus.dispose();
    variables.dispose();
    objects.dispose();
    clock.dispose();
  }
}

