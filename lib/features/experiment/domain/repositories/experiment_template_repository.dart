import '../models/experiment_models.dart';

abstract class ExperimentTemplateRepository {
  Future<List<ExperimentManifest>> getTemplates();
  Future<ExperimentManifest?> getTemplate(String id);
}
