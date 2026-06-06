import '../../domain/repositories/experiment_manifest_execution_repository.dart';
import '../experiment_api_service.dart';

class ExperimentManifestExecutionRepositoryImpl implements ExperimentManifestExecutionRepository {
  final ExperimentApiService _apiService;

  ExperimentManifestExecutionRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>?> getExecutionDefinition(String manifestId) async {
    return await _apiService.fetchExecutionDefinition(manifestId);
  }
}
