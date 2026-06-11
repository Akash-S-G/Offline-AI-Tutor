import '../../runtime/observations/runtime_observation.dart';
import 'trial_snapshot.dart';
import 'trial_status.dart';

class ExperimentTrial {
  final String trialId;
  String get id => trialId;
  final int trialNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> parameterValues;
  Map<String, dynamic> get parameterSnapshot => parameterValues;
  final List<RuntimeObservation> observations;
  final Map<String, dynamic> measurements;
  final DateTime timestamp;
  final Duration duration;
  final TrialSnapshot? snapshot;
  final String notes;
  final TrialStatus status;

  const ExperimentTrial({
    required this.trialId,
    required this.trialNumber,
    required this.startTime,
    this.endTime,
    this.parameterValues = const {},
    this.observations = const [],
    this.measurements = const {},
    required this.timestamp,
    this.duration = Duration.zero,
    this.snapshot,
    this.notes = '',
    this.status = TrialStatus.running,
  });

  ExperimentTrial copyWith({
    DateTime? endTime,
    Map<String, dynamic>? parameterValues,
    List<RuntimeObservation>? observations,
    Map<String, dynamic>? measurements,
    Duration? duration,
    TrialSnapshot? snapshot,
    String? notes,
    TrialStatus? status,
  }) {
    return ExperimentTrial(
      trialId: trialId,
      trialNumber: trialNumber,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      parameterValues: parameterValues ?? this.parameterValues,
      observations: observations ?? this.observations,
      measurements: measurements ?? this.measurements,
      timestamp: timestamp,
      duration: duration ?? this.duration,
      snapshot: snapshot ?? this.snapshot,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trialId': trialId,
      'id': trialId,
      'trialNumber': trialNumber,
      'startTime': startTime.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      'parameterValues': parameterValues,
      'observations': observations
          .map((observation) => observation.toJson())
          .toList(),
      'measurements': measurements,
      'timestamp': timestamp.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      if (snapshot != null) 'snapshot': snapshot!.toJson(),
      'notes': notes,
      'status': status.name,
    };
  }
}
