import 'dart:async';

import '../runtime_event.dart';
import '../runtime_event_bus.dart';
import 'runtime_experiment_events.dart';
import 'runtime_experiment_metrics.dart';
import 'runtime_experiment_state.dart';
import 'runtime_experiment_status.dart';

class RuntimeExperimentStateManager {
  final RuntimeEventBus eventBus;
  RuntimeExperimentState _state;
  StreamSubscription<RuntimeEvent>? _subscription;

  RuntimeExperimentStateManager({
    required this.eventBus,
    String experimentId = 'experiment',
  }) : _state = RuntimeExperimentState.created(experimentId);

  RuntimeExperimentState get state => _state;

  void restore(RuntimeExperimentState state) {
    _state = state;
    _emit('ExperimentStateRestored');
  }

  void attach() {
    _subscription?.cancel();
    _subscription = eventBus.stream.listen(_handleEvent);
  }

  void initialize({
    required String experimentId,
    required int variables,
    required int objects,
    required int rules,
  }) {
    _state = RuntimeExperimentState.created(experimentId).copyWith(
      status: RuntimeExperimentStatus.prepared,
      metrics: RuntimeExperimentMetrics(
        variables: variables,
        objects: objects,
        rules: rules,
        measurements: 0,
        observations: 0,
        warnings: 0,
        rulesTriggered: 0,
        graphUpdates: 0,
        sensorUpdates: 0,
      ),
    );
    _emit('ExperimentPrepared');
  }

  void start() {
    _state = _state.copyWith(
      status: RuntimeExperimentStatus.running,
      startedAt: DateTime.now(),
      completedAt: null,
    );
    _emit('ExperimentStarted');
  }

  void pause() {
    _state = _state.copyWith(status: RuntimeExperimentStatus.paused);
    _emit('ExperimentPaused');
  }

  void resume() {
    _state = _state.copyWith(status: RuntimeExperimentStatus.running);
    _emit('ExperimentResumed');
  }

  void stop() {
    _state = _state.copyWith(status: RuntimeExperimentStatus.stopped);
    _emit('ExperimentStopped');
  }

  void complete() {
    _state = _state.copyWith(
      status: RuntimeExperimentStatus.completed,
      completedAt: DateTime.now(),
    );
    _emit('ExperimentCompleted');
  }

  void fail([String? reason]) {
    _state = _state.copyWith(status: RuntimeExperimentStatus.failed);
    _emit('ExperimentFailed', metadata: {'reason': reason});
  }

  void tick(double dt) {
    if (_state.status != RuntimeExperimentStatus.running) return;
    _state = _state.copyWith(
      runtime: _state.runtime + Duration(milliseconds: (dt * 1000).round()),
    );
  }

  void _handleEvent(RuntimeEvent event) {
    if (event.message == 'MeasurementCollected') {
      _increment(measurements: 1);
    } else if (event.message == 'ObservationRecorded') {
      _increment(observations: 1);
    } else if (event.type == RuntimeEventType.warning ||
        event.message == 'WarningGenerated') {
      _increment(warnings: 1);
    } else if (event.message == 'RuleTriggered' ||
        event.message == 'RuleFired') {
      _increment(rulesTriggered: 1);
    } else if (event.message == 'GraphUpdated' ||
        event.message == 'ScatterPlotUpdated') {
      _increment(graphUpdates: 1);
    } else if (event.type == RuntimeEventType.measurementReceived ||
        event.message == 'SensorMeasurementReceived') {
      _increment(sensorUpdates: 1);
    } else if (event.message == 'ExperimentCompleted') {
      if (_state.status != RuntimeExperimentStatus.completed) {
        complete();
      }
    }
  }

  void _increment({
    int measurements = 0,
    int observations = 0,
    int warnings = 0,
    int rulesTriggered = 0,
    int graphUpdates = 0,
    int sensorUpdates = 0,
  }) {
    final metrics = _state.metrics.copyWith(
      measurements: _state.metrics.measurements + measurements,
      observations: _state.metrics.observations + observations,
      warnings: _state.metrics.warnings + warnings,
      rulesTriggered: _state.metrics.rulesTriggered + rulesTriggered,
      graphUpdates: _state.metrics.graphUpdates + graphUpdates,
      sensorUpdates: _state.metrics.sensorUpdates + sensorUpdates,
    );
    _state = _state.copyWith(
      measurements: _state.measurements + measurements,
      observations: _state.observations + observations,
      warnings: _state.warnings + warnings,
      rulesTriggered: _state.rulesTriggered + rulesTriggered,
      metrics: metrics,
    );
  }

  void _emit(String message, {Map<String, dynamic>? metadata}) {
    eventBus.emit(experimentStateEvent(message, _state, metadata: metadata));
  }

  void dispose() {
    _subscription?.cancel();
  }
}
