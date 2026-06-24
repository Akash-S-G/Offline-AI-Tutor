import '../api/ai_experiment_api_service.dart';

class AiGeneratedExperiment {
  final Map<String, dynamic> manifest;
  final Map<String, dynamic> explanation;

  AiGeneratedExperiment({required this.manifest, required this.explanation});
}

abstract class AiExperimentRepository {
  Future<AiGeneratedExperiment> generateExperiment(String prompt, {String? language});
  Future<AiGeneratedExperiment> refineExperiment(Map<String, dynamic> manifest, String prompt, {String? language});
  Future<Map<String, dynamic>> explainExperiment(Map<String, dynamic> manifest, {String? language});
}

class AiExperimentRepositoryImpl implements AiExperimentRepository {
  final AiExperimentApiService _apiService;

  AiExperimentRepositoryImpl(this._apiService);

  @override
  Future<AiGeneratedExperiment> generateExperiment(String prompt, {String? language}) async {
    final response = await _apiService.generateExperiment(prompt, language: language);
    return AiGeneratedExperiment(
      manifest: response['manifest'] as Map<String, dynamic>? ?? {},
      explanation: response['explanation'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Future<AiGeneratedExperiment> refineExperiment(Map<String, dynamic> manifest, String prompt, {String? language}) async {
    final response = await _apiService.refineExperiment(manifest, prompt, language: language);
    return AiGeneratedExperiment(
      manifest: response['manifest'] as Map<String, dynamic>? ?? {},
      explanation: response['explanation'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Future<Map<String, dynamic>> explainExperiment(Map<String, dynamic> manifest, {String? language}) async {
    final response = await _apiService.explainExperiment(manifest, language: language);
    return response['explanation'] as Map<String, dynamic>? ?? {};
  }
}
