import '../../runtime/runtime_event.dart';

class ExperimentEventDto {
  final String eventId;
  final String runId;
  final String eventType;
  final DateTime timestamp;
  final String message;
  final Map<String, dynamic>? metadata;

  ExperimentEventDto({
    required this.eventId,
    required this.runId,
    required this.eventType,
    required this.timestamp,
    required this.message,
    this.metadata,
  });

  factory ExperimentEventDto.fromRuntimeEvent(String runId, RuntimeEvent event) {
    return ExperimentEventDto(
      eventId: event.id,
      runId: runId,
      eventType: event.type.name,
      timestamp: event.timestamp,
      message: event.message,
      metadata: event.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'run_id': runId,
      'event_type': eventType,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory ExperimentEventDto.fromJson(Map<String, dynamic> json) {
    return ExperimentEventDto(
      eventId: json['event_id'],
      runId: json['run_id'],
      eventType: json['event_type'],
      timestamp: DateTime.parse(json['timestamp']),
      message: json['message'],
      metadata: json['metadata'],
    );
  }
}
