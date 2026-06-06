import '../models/experiment_models.dart';

abstract class ExperimentRunRepository {
  Future<ExperimentRun> startRun(String experimentId);
  Future<void> completeRun(String runId, ExperimentResult result);
  Future<List<ExperimentRun>> getRunHistory(String experimentId);
}
