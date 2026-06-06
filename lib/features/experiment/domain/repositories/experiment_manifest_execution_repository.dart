abstract class ExperimentManifestExecutionRepository {
  Future<Map<String, dynamic>?> getExecutionDefinition(String manifestId);
}
