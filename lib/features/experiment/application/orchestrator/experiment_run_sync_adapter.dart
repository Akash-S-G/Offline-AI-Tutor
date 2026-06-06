import '../../data/models/experiment_run_dto.dart';
import '../../data/models/experiment_event_dto.dart';

abstract class ExperimentRunSyncAdapter {
  Future<void> createRun(ExperimentRunDto run);
  Future<void> appendEvent(String runId, ExperimentEventDto event);
  Future<void> completeRun(String runId, Map<String, dynamic> metrics);
  Future<void> syncMetrics();
}
