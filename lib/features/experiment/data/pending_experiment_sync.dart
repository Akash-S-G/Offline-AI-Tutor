import 'models/experiment_run_dto.dart';
import 'models/experiment_event_dto.dart';

enum SyncOperationType {
  createRun,
  appendEvents,
  completeRun,
}

class PendingExperimentSync {
  final String id;
  final SyncOperationType operationType;
  final ExperimentRunDto? runDto;
  final List<ExperimentEventDto>? events;
  final String? runId;
  int retryCount;

  PendingExperimentSync({
    required this.id,
    required this.operationType,
    this.runDto,
    this.events,
    this.runId,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operationType': operationType.name,
      'runDto': runDto?.toJson(),
      'events': events?.map((e) => e.toJson()).toList(),
      'runId': runId,
      'retryCount': retryCount,
    };
  }

  factory PendingExperimentSync.fromJson(Map<String, dynamic> json) {
    return PendingExperimentSync(
      id: json['id'],
      operationType: SyncOperationType.values.firstWhere((e) => e.name == json['operationType']),
      runDto: json['runDto'] != null ? ExperimentRunDto.fromJson(json['runDto']) : null,
      events: json['events'] != null 
          ? (json['events'] as List).map((e) => ExperimentEventDto.fromJson(e)).toList() 
          : null,
      runId: json['runId'],
      retryCount: json['retryCount'] ?? 0,
    );
  }
}
