import '../models/experiment_models.dart';

abstract class ExperimentRepository {
  Future<ExperimentManifest?> getExperiment(String id);
  Future<List<ExperimentManifest>> getExperiments();
  Future<void> saveExperiment(ExperimentManifest experiment);
}
