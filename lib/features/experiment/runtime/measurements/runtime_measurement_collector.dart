import 'dart:async';

import '../models/runtime_variable.dart';
import '../runtime_event.dart';
import '../runtime_event_bus.dart';
import '../runtime_variable_events.dart';
import '../variable_store.dart';
import 'runtime_measurement.dart';
import 'runtime_measurement_events.dart';
import 'runtime_measurement_policy.dart';
import 'runtime_measurement_store.dart';

class RuntimeMeasurementCollector {
  final VariableStore variables;
  final RuntimeEventBus eventBus;
  final RuntimeMeasurementStore store;
  final double Function() runtimeSecondsProvider;

  final Map<String, RuntimeMeasurementPolicy> _policies = {};
  final Map<String, double> _periodSeconds = {};
  final Map<String, double> _lastPeriodicCapture = {};
  StreamSubscription<RuntimeEvent>? _subscription;

  RuntimeMeasurementCollector({
    required this.variables,
    required this.eventBus,
    required this.store,
    required this.runtimeSecondsProvider,
  });

  void initialize() {
    _policies.clear();
    _periodSeconds.clear();
    _lastPeriodicCapture.clear();
    for (final variable in variables.getAllVariables()) {
      _policies[variable.id] = inferPolicy(variable);
      _periodSeconds[variable.id] = _periodFor(variable);
    }
    _subscription?.cancel();
    _subscription = eventBus.stream.listen(_handleRuntimeEvent);
  }

  RuntimeMeasurementPolicy policyFor(String variableId) {
    return _policies[variableId] ?? RuntimeMeasurementPolicy.onChange;
  }

  void clearMeasurements(String variableId) {
    final count = store.clearMeasurements(variableId);
    eventBus.emit(
      measurementsClearedEvent(variableId: variableId, count: count),
    );
  }

  void clearAllMeasurements() {
    final count = store.clearAllMeasurements();
    eventBus.emit(measurementsClearedEvent(count: count));
  }

  void _handleRuntimeEvent(RuntimeEvent event) {
    if (event.message != 'VariableUpdated') return;
    if (event.metadata?['variableEventType'] !=
        RuntimeVariableEventType.variableUpdated.name) {
      return;
    }
    final variableId = event.metadata?['variableId']?.toString();
    if (variableId == null || variableId.isEmpty) return;
    final variable = variables.getVariable(variableId);
    if (variable == null) return;

    _policies.putIfAbsent(variable.id, () => inferPolicy(variable));
    _periodSeconds.putIfAbsent(variable.id, () => _periodFor(variable));
    final policy = policyFor(variable.id);
    final runtimeSeconds = runtimeSecondsProvider();
    final observedValue = event.metadata?['newValue'];
    if (!_shouldCollect(variable, observedValue, policy, runtimeSeconds)) {
      return;
    }

    final measurement = RuntimeMeasurement(
      variableId: variable.id,
      variableName: variable.name,
      value: observedValue,
      timestamp: DateTime.now(),
      runtimeSeconds: runtimeSeconds,
      source: event.metadata?['source']?.toString() ?? 'runtime',
    );
    final discarded = store.addMeasurement(measurement);
    eventBus.emit(measurementCollectedEvent(measurement));
    for (final sample in discarded) {
      eventBus.emit(measurementDiscardedEvent(sample));
    }
  }

  bool _shouldCollect(
    RuntimeVariable variable,
    dynamic observedValue,
    RuntimeMeasurementPolicy policy,
    double runtimeSeconds,
  ) {
    switch (policy) {
      case RuntimeMeasurementPolicy.everyUpdate:
        return true;
      case RuntimeMeasurementPolicy.onChange:
        final latest = store.getLatestMeasurement(variable.id);
        return latest == null || latest.value != observedValue;
      case RuntimeMeasurementPolicy.periodic:
        final lastRuntime = _lastPeriodicCapture[variable.id];
        final period = _periodSeconds[variable.id] ?? 1;
        if (lastRuntime != null && runtimeSeconds - lastRuntime < period) {
          return false;
        }
        _lastPeriodicCapture[variable.id] = runtimeSeconds;
        return true;
    }
  }

  RuntimeMeasurementPolicy inferPolicy(RuntimeVariable variable) {
    final configured =
        variable.metadata['measurementPolicy'] ??
        variable.metadata['historyPolicy'] ??
        variable.metadata['collectionPolicy'];
    if (configured != null) {
      return measurementPolicyFromName(configured.toString());
    }
    return RuntimeMeasurementPolicy.onChange;
  }

  double _periodFor(RuntimeVariable variable) {
    final value =
        variable.metadata['measurementPeriod'] ??
        variable.metadata['period'] ??
        variable.metadata['sampleInterval'] ??
        variable.metadata['intervalSeconds'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 1;
  }

  void dispose() {
    _subscription?.cancel();
    _policies.clear();
    _periodSeconds.clear();
    _lastPeriodicCapture.clear();
  }
}
