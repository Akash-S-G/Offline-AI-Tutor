import '../../../runtime/runtime_event.dart';

class VisualizationState {
  final Map<String, dynamic> variables;
  final Map<String, Map<String, dynamic>> objectStates;
  final Map<String, Map<String, dynamic>> measurements;
  final List<RuntimeEvent> timeline;
  
  final int measurementsReceived;
  final int warnings;
  final int errors;
  final int eventsProcessed;
  final Duration runtimeDuration;

  VisualizationState({
    required this.variables,
    required this.objectStates,
    required this.measurements,
    required this.timeline,
    required this.measurementsReceived,
    required this.warnings,
    required this.errors,
    required this.eventsProcessed,
    required this.runtimeDuration,
  });

  VisualizationState copyWith({
    Map<String, dynamic>? variables,
    Map<String, Map<String, dynamic>>? objectStates,
    Map<String, Map<String, dynamic>>? measurements,
    List<RuntimeEvent>? timeline,
    int? measurementsReceived,
    int? warnings,
    int? errors,
    int? eventsProcessed,
    Duration? runtimeDuration,
  }) {
    return VisualizationState(
      variables: variables ?? this.variables,
      objectStates: objectStates ?? this.objectStates,
      measurements: measurements ?? this.measurements,
      timeline: timeline ?? this.timeline,
      measurementsReceived: measurementsReceived ?? this.measurementsReceived,
      warnings: warnings ?? this.warnings,
      errors: errors ?? this.errors,
      eventsProcessed: eventsProcessed ?? this.eventsProcessed,
      runtimeDuration: runtimeDuration ?? this.runtimeDuration,
    );
  }

  factory VisualizationState.initial() {
    return VisualizationState(
      variables: {},
      objectStates: {},
      measurements: {},
      timeline: [],
      measurementsReceived: 0,
      warnings: 0,
      errors: 0,
      eventsProcessed: 0,
      runtimeDuration: Duration.zero,
    );
  }
}
