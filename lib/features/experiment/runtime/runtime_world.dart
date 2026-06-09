import 'bindings/runtime_binding_engine.dart';
import 'bindings/runtime_binding_registry.dart';
import 'experiment_state/runtime_experiment_snapshot.dart';
import 'experiment_state/runtime_experiment_state_manager.dart';
import 'interactions/runtime_interaction_bus.dart';
import 'interactions/runtime_object_variable_adapter.dart';
import 'measurements/runtime_measurement_collector.dart';
import 'measurements/runtime_measurement_store.dart';
import 'objects/behavior/runtime_object_behavior_registry.dart';
import 'objects/renderers/runtime_object_renderer_registry.dart';
import 'objects/runtime_object_lifecycle_manager.dart';
import 'objects/schema/runtime_object_schema_registry.dart';
import 'observations/runtime_observation.dart';
import 'observations/runtime_observation_exporter.dart';
import 'observations/runtime_observation_scheduler.dart';
import 'observations/runtime_observation_store.dart';
import 'variable_store.dart';
import 'object_registry.dart';
import 'rule_engine.dart';
import 'runtime_event_bus.dart';
import 'simulation_clock.dart';
import 'runtime_analytics.dart';
import 'runtime_profiles.dart';
import 'variables/runtime_variable_executor.dart';

class RuntimeWorld {
  late final VariableStore variables;
  late final RuntimeExperimentStateManager experimentState;
  late final ObjectRegistry objects;
  late final RuntimeObjectSchemaRegistry objectSchemas;
  late final RuntimeObjectBehaviorRegistry objectBehaviors;
  late final RuntimeObjectRendererRegistry objectRenderers;
  late final RuntimeObjectLifecycleManager objectLifecycle;
  late final RuntimeBindingRegistry bindings;
  late final RuntimeBindingEngine bindingEngine;
  late final RuntimeMeasurementStore measurementStore;
  late final RuntimeMeasurementCollector measurementCollector;
  late final RuntimeObservationStore observationStore;
  late final RuntimeObservationScheduler observationScheduler;
  late final RuntimeObservationExporter observationExporter;
  late final RuntimeInteractionBus interactionBus;
  late final RuntimeObjectVariableAdapter objectVariableAdapter;
  late final RuntimeVariableExecutor variableExecutor;
  late final RuleEngine rules;
  late final RuntimeEventBus eventBus;
  late final SimulationClock clock;
  late final RuntimeAnalytics analytics;

  RuntimeProfile profile = RuntimeProfile.general;
  Map<String, dynamic> metadata = {};

  RuntimeWorld() {
    eventBus = RuntimeEventBus();
    experimentState = RuntimeExperimentStateManager(eventBus: eventBus)
      ..attach();
    variables = VariableStore(eventBus: eventBus);
    objects = ObjectRegistry();
    objectSchemas = RuntimeObjectSchemaRegistry();
    objectBehaviors = RuntimeObjectBehaviorRegistry();
    objectRenderers = RuntimeObjectRendererRegistry();
    objectLifecycle = RuntimeObjectLifecycleManager(
      schemaRegistry: objectSchemas,
      behaviorRegistry: objectBehaviors,
      rendererRegistry: objectRenderers,
      eventBus: eventBus,
    );
    objects.attachLifecycleManager(objectLifecycle);
    bindings = RuntimeBindingRegistry();
    measurementStore = RuntimeMeasurementStore();
    measurementCollector = RuntimeMeasurementCollector(
      variables: variables,
      eventBus: eventBus,
      store: measurementStore,
      runtimeSecondsProvider: () => clock.elapsedTime,
    );
    observationStore = RuntimeObservationStore();
    observationScheduler = RuntimeObservationScheduler(
      variables: variables,
      store: observationStore,
      eventBus: eventBus,
      runtimeSecondsProvider: () => clock.elapsedTime,
    );
    observationExporter = RuntimeObservationExporter(
      store: observationStore,
      eventBus: eventBus,
    );
    interactionBus = RuntimeInteractionBus(runtimeEventBus: eventBus);
    bindingEngine = RuntimeBindingEngine(
      variables: variables,
      objects: objects,
      registry: bindings,
      eventBus: eventBus,
    );
    objectVariableAdapter = RuntimeObjectVariableAdapter(
      variables: variables,
      objects: objects,
      bindings: bindings,
      interactionBus: interactionBus,
    );
    variableExecutor = RuntimeVariableExecutor(
      variables: variables,
      eventBus: eventBus,
    );
    clock = SimulationClock();
    analytics = RuntimeAnalytics();
    rules = RuleEngine(variables, eventBus, objects);
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
    experimentState.initialize(
      experimentId: _experimentIdFromMetadata(curriculumMetadata),
      variables: variablesJson.length,
      objects: objectsJson.length,
      rules: rulesJson.length,
    );
    measurementCollector.initialize();
    variableExecutor.initialize();
    objects.initialize(objectsJson);
    bindingEngine.initialize(objectsJson);
    rules.initialize(rulesJson);
    clock.reset();
    analytics.recordLaunch();
  }

  void tick(double dt) {
    if (clock.isRunning) {
      clock.tick(dt);
      analytics.addTimeSpent(dt);
      experimentState.tick(dt);
      variableExecutor.tick(dt);
      observationScheduler.tick(dt);
      rules.evaluateContinuousRules(dt);
    }
  }

  void start() {
    clock.start();
    experimentState.start();
  }

  void pause() {
    clock.pause();
    experimentState.pause();
  }

  void resume() {
    clock.start();
    experimentState.resume();
  }

  void stop() {
    clock.reset();
    experimentState.stop();
  }

  void complete() {
    experimentState.complete();
  }

  void fail([String? reason]) {
    experimentState.fail(reason);
  }

  RuntimeObservation recordObservation({String source = 'manual'}) {
    return observationScheduler.recordObservation(source: source);
  }

  RuntimeExperimentSnapshot createSnapshot() {
    return RuntimeExperimentSnapshot(
      variables: variables.allRuntimeVariables,
      objectStates: objects.allObjectStates,
      measurementsCount: measurementStore.trackedVariableIds.fold<int>(
        0,
        (count, variableId) => count + measurementStore.sampleCount(variableId),
      ),
      observationsCount: observationStore.rowCount,
      state: experimentState.state,
    );
  }

  void dispose() {
    analytics.dispose();
    experimentState.dispose();
    rules.dispose();
    variableExecutor.dispose();
    measurementCollector.dispose();
    objectLifecycle.dispose();
    bindingEngine.dispose();
    interactionBus.dispose();
    eventBus.dispose();
    variables.dispose();
    objects.dispose();
    clock.dispose();
  }

  String _experimentIdFromMetadata(Map<String, dynamic> metadata) {
    return metadata['id']?.toString() ??
        metadata['sceneId']?.toString() ??
        metadata['title']?.toString() ??
        metadata['name']?.toString() ??
        'experiment';
  }
}
