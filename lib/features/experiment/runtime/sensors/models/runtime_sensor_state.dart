import 'runtime_sensor_type.dart';

class RuntimeSensorState {
  final RuntimeSensorType type;
  final bool registered;
  final bool active;
  final bool paused;
  final bool available;
  final int measurementCount;
  final DateTime? startedAt;
  final DateTime? stoppedAt;
  final DateTime? lastMeasurementAt;
  final String? lastError;
  final String? warning;

  const RuntimeSensorState({
    required this.type,
    this.registered = false,
    this.active = false,
    this.paused = false,
    this.available = false,
    this.measurementCount = 0,
    this.startedAt,
    this.stoppedAt,
    this.lastMeasurementAt,
    this.lastError,
    this.warning,
  });

  RuntimeSensorState copyWith({
    bool? registered,
    bool? active,
    bool? paused,
    bool? available,
    int? measurementCount,
    DateTime? startedAt,
    DateTime? stoppedAt,
    DateTime? lastMeasurementAt,
    String? lastError,
    String? warning,
    bool clearError = false,
  }) {
    return RuntimeSensorState(
      type: type,
      registered: registered ?? this.registered,
      active: active ?? this.active,
      paused: paused ?? this.paused,
      available: available ?? this.available,
      measurementCount: measurementCount ?? this.measurementCount,
      startedAt: startedAt ?? this.startedAt,
      stoppedAt: stoppedAt ?? this.stoppedAt,
      lastMeasurementAt: lastMeasurementAt ?? this.lastMeasurementAt,
      lastError: clearError ? null : lastError ?? this.lastError,
      warning: warning ?? this.warning,
    );
  }
}
