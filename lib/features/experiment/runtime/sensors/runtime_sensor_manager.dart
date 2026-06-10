import 'dart:async';

import '../models/runtime_variable.dart';
import '../runtime_event_bus.dart';
import '../variable_store.dart';
import 'models/runtime_sensor.dart';
import 'models/runtime_sensor_state.dart';
import 'models/runtime_sensor_type.dart';
import 'runtime_sensor_events.dart';
import 'sensor_measurement.dart';
import 'sensor_registry.dart';
import 'sensor_type.dart';

class RuntimeSensorManager {
  final VariableStore variables;
  final RuntimeEventBus eventBus;
  final SensorRegistry registry;

  final Map<String, RuntimeSensor> _sensorsByVariableId = {};
  final Map<RuntimeSensorType, StreamSubscription<SensorMeasurement>>
  _subscriptions = {};
  final Map<RuntimeSensorType, RuntimeSensorState> _states = {};
  bool _paused = false;
  bool _disposed = false;

  RuntimeSensorManager({
    required this.variables,
    required this.eventBus,
    SensorRegistry? registry,
  }) : registry = registry ?? SensorRegistry();

  List<RuntimeSensor> get registeredSensors =>
      List.unmodifiable(_sensorsByVariableId.values);

  List<RuntimeSensorState> get sensorStates {
    final states = <RuntimeSensorType, RuntimeSensorState>{..._states};
    for (final sensor in _sensorsByVariableId.values) {
      states.putIfAbsent(sensor.type, () => sensor.state);
    }
    return List.unmodifiable(states.values);
  }

  int get activeSensorCount =>
      sensorStates.where((state) => state.active && !state.paused).length;

  void initialize() {
    _sensorsByVariableId.clear();
    _states.clear();
    registerVariables(variables.getAllVariables());
  }

  void registerVariables(Iterable<RuntimeVariable> runtimeVariables) {
    for (final variable in runtimeVariables) {
      final type = runtimeSensorTypeFromVariableType(variable.type);
      if (type == null || variable.id.isEmpty) continue;
      final sensor = RuntimeSensor.fromVariable(variable);
      _sensorsByVariableId[variable.id] = sensor;
      _states[type] = (_states[type] ?? RuntimeSensorState(type: type))
          .copyWith(registered: true);
      eventBus.emit(
        sensorVariableRegisteredEvent(
          variableId: variable.id,
          variableName: variable.name,
          sensorType: type,
        ),
      );
    }
  }

  Future<void> start() async {
    if (_disposed) return;
    _paused = false;
    for (final type in _registeredTypes) {
      await _startType(type);
    }
  }

  void pause() {
    _paused = true;
    for (final entry in _states.entries) {
      _states[entry.key] = entry.value.copyWith(paused: true);
    }
  }

  Future<void> resume() async {
    if (_disposed) return;
    _paused = false;
    for (final entry in _states.entries) {
      _states[entry.key] = entry.value.copyWith(paused: false);
    }
    for (final type in _registeredTypes) {
      if (!_subscriptions.containsKey(type)) {
        await _startType(type);
      }
    }
  }

  Future<void> stop() async {
    for (final type in _subscriptions.keys.toList(growable: false)) {
      await _stopType(type);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    for (final type in SensorType.values) {
      await registry.getProvider(type)?.dispose();
    }
  }

  void injectMeasurement(SensorMeasurement measurement) {
    _handleMeasurement(measurement);
  }

  Set<RuntimeSensorType> get _registeredTypes =>
      _sensorsByVariableId.values.map((sensor) => sensor.type).toSet();

  Future<void> _startType(RuntimeSensorType type) async {
    if (_subscriptions.containsKey(type)) return;
    final providerType = type.providerType;
    final provider = registry.getProvider(providerType);
    if (provider == null) {
      _recordError(type, 'Unknown sensor provider');
      return;
    }

    try {
      await provider.initialize();
      final available = await provider.isAvailable();
      if (!available) {
        _recordError(type, 'Sensor provider unavailable');
        return;
      }
      await provider.start();
      _subscriptions[type] = provider.measurementStream.listen(
        _handleMeasurement,
        onError: (Object error) => _recordError(type, error.toString()),
      );
      _states[type] = (_states[type] ?? RuntimeSensorState(type: type))
          .copyWith(
            active: true,
            paused: false,
            available: true,
            startedAt: DateTime.now(),
            clearError: true,
          );
      _emit(sensorStartedEvent(type));
    } catch (error) {
      final message = error.toString();
      if (message.toLowerCase().contains('permission')) {
        _emit(sensorPermissionDeniedEvent(sensorType: type, reason: message));
      }
      _recordError(type, message);
    }
  }

  Future<void> _stopType(RuntimeSensorType type) async {
    await _subscriptions.remove(type)?.cancel();
    await registry.getProvider(type.providerType)?.stop();
    final current = _states[type] ?? RuntimeSensorState(type: type);
    _states[type] = current.copyWith(
      active: false,
      paused: false,
      stoppedAt: DateTime.now(),
    );
    _emit(sensorStoppedEvent(type));
  }

  void _handleMeasurement(SensorMeasurement measurement) {
    final type = _runtimeTypeForProvider(measurement.sensorType);
    if (type == null || _paused) return;
    final targets = _sensorsByVariableId.values
        .where((sensor) => sensor.type == type)
        .toList(growable: false);
    if (targets.isEmpty) return;

    final values = Map<String, dynamic>.from(measurement.values);
    final metadata = <String, dynamic>{
      'sensorType': type.name,
      'timestamp': measurement.timestamp.toIso8601String(),
      ...?measurement.metadata,
    };
    final current = _states[type] ?? RuntimeSensorState(type: type);
    _states[type] = current.copyWith(
      registered: true,
      active: true,
      available: true,
      paused: false,
      measurementCount: current.measurementCount + targets.length,
      lastMeasurementAt: measurement.timestamp,
      warning: measurement.metadata?['warning']?.toString(),
      clearError: true,
    );

    for (final sensor in targets) {
      variables.updateVariable(
        sensor.variableId,
        values,
        source: 'sensor:${type.name}',
        metadata: metadata,
      );
      _emit(
        sensorMeasurementReceivedEvent(
          sensorType: type,
          variableId: sensor.variableId,
          values: values,
          metadata: metadata,
        ),
      );
    }
  }

  void _recordError(RuntimeSensorType type, String message) {
    final current = _states[type] ?? RuntimeSensorState(type: type);
    _states[type] = current.copyWith(
      registered: true,
      active: false,
      available: false,
      lastError: message,
    );
    _emit(sensorErrorEvent(sensorType: type, message: message));
  }

  void _emit(dynamic event) {
    if (!_disposed) {
      eventBus.emit(event);
    }
  }

  RuntimeSensorType? _runtimeTypeForProvider(SensorType type) {
    switch (type) {
      case SensorType.accelerometer:
        return RuntimeSensorType.accelerometer;
      case SensorType.gyroscope:
        return RuntimeSensorType.gyroscope;
      case SensorType.magnetometer:
        return RuntimeSensorType.magnetometer;
      case SensorType.gps:
        return RuntimeSensorType.gps;
      case SensorType.light:
        return RuntimeSensorType.light;
      case SensorType.proximity:
        return RuntimeSensorType.proximity;
      case SensorType.microphone:
        return RuntimeSensorType.microphone;
      case SensorType.barometer:
        return RuntimeSensorType.barometer;
    }
  }
}
