import '../runtime_event_bus.dart';
import '../variable_store.dart';
import 'runtime_observation.dart';
import 'runtime_observation_events.dart';
import 'runtime_observation_store.dart';

class RuntimeObservationScheduler {
  final VariableStore variables;
  final RuntimeObservationStore store;
  final RuntimeEventBus eventBus;
  final double Function() runtimeSecondsProvider;

  ObservationCollectionMode collectionMode = ObservationCollectionMode.manual;
  double intervalSeconds = 1;
  double _elapsedSinceLastObservation = 0;

  RuntimeObservationScheduler({
    required this.variables,
    required this.store,
    required this.eventBus,
    required this.runtimeSecondsProvider,
  });

  void tick(double dt) {
    if (collectionMode != ObservationCollectionMode.interval) return;
    _elapsedSinceLastObservation += dt;
    while (_elapsedSinceLastObservation >= intervalSeconds) {
      _elapsedSinceLastObservation -= intervalSeconds;
      recordObservation(source: 'interval');
    }
  }

  RuntimeObservation recordObservation({String source = 'manual'}) {
    final observation = RuntimeObservation(
      id: 'observation_${DateTime.now().microsecondsSinceEpoch}',
      runtimeSeconds: runtimeSecondsProvider(),
      timestamp: DateTime.now(),
      values: _currentValues(),
      source: source,
    );
    store.addObservation(observation);
    eventBus.emit(observationRecordedEvent(observation));
    return observation;
  }

  RuntimeObservation? removeObservation(String id) {
    final removed = store.removeObservation(id);
    if (removed != null) {
      eventBus.emit(observationRemovedEvent(removed));
    }
    return removed;
  }

  void clearObservations() {
    final count = store.clearObservations();
    eventBus.emit(observationsClearedEvent(count: count));
  }

  void configureInterval({required double seconds}) {
    collectionMode = ObservationCollectionMode.interval;
    intervalSeconds = seconds <= 0 ? 1 : seconds;
    _elapsedSinceLastObservation = 0;
  }

  void configureManual() {
    collectionMode = ObservationCollectionMode.manual;
    _elapsedSinceLastObservation = 0;
  }

  int get recordedVariableCount => variables.getAllVariables().length;

  Map<String, dynamic> _currentValues() {
    final values = <String, dynamic>{};
    for (final variable in variables.getAllVariables()) {
      values[variable.name] = variable.value;
    }
    return values;
  }
}
