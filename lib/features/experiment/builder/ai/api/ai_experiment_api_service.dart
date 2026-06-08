import 'dart:convert';
import '../../../../network/data/backend_http_client.dart';
import '../../../../network/domain/backend_config.dart';

class AiExperimentApiService {
  final BackendHttpClient _client;

  AiExperimentApiService(BackendConfig config)
      : _client = BackendHttpClient(config: config);

  Future<Map<String, dynamic>> generateExperiment(String prompt) async {
    final response = await _client.post('/ai/experiment/generate', body: {'prompt': prompt});
    if (response.isSuccess && response.data != null) {
      return jsonDecode(response.data!) as Map<String, dynamic>;
    }
    throw Exception('Failed to generate experiment: ${response.message}');
  }

  Future<Map<String, dynamic>> refineExperiment(Map<String, dynamic> manifest, String prompt) async {
    final response = await _client.post('/ai/experiment/refine', body: {'manifest': manifest, 'prompt': prompt});
    if (response.isSuccess && response.data != null) {
      return jsonDecode(response.data!) as Map<String, dynamic>;
    }
    throw Exception('Failed to refine experiment: ${response.message}');
  }

  Future<Map<String, dynamic>> explainExperiment(Map<String, dynamic> manifest) async {
    final response = await _client.post('/ai/experiment/explain', body: {'manifest': manifest});
    if (response.isSuccess && response.data != null) {
      return jsonDecode(response.data!) as Map<String, dynamic>;
    }
    throw Exception('Failed to explain experiment: ${response.message}');
  }
}
