import 'dart:convert';
import '../../../../network/data/backend_http_client.dart';
import '../../../../network/domain/backend_config.dart';

class ExperimentManifestApiService {
  final BackendHttpClient _client;

  ExperimentManifestApiService(BackendConfig config)
      : _client = BackendHttpClient(config: config);

  Future<Map<String, dynamic>> validateManifest(Map<String, dynamic> manifest) async {
    final response = await _client.post('/manifest/validate', body: manifest);
    if (response.isSuccess && response.data != null) {
      return jsonDecode(response.data!) as Map<String, dynamic>;
    }
    throw Exception('Failed to validate manifest: ${response.message}');
  }

  Future<Map<String, dynamic>> checkCompatibility(Map<String, dynamic> manifest) async {
    final response = await _client.post('/manifest/compatibility', body: manifest);
    if (response.isSuccess && response.data != null) {
      return jsonDecode(response.data!) as Map<String, dynamic>;
    }
    throw Exception('Failed to check compatibility: ${response.message}');
  }

  Future<Map<String, dynamic>> migrateManifest(Map<String, dynamic> manifest) async {
    final response = await _client.post('/manifest/migrate', body: manifest);
    if (response.isSuccess && response.data != null) {
      return jsonDecode(response.data!) as Map<String, dynamic>;
    }
    throw Exception('Failed to migrate manifest: ${response.message}');
  }

  Future<Map<String, dynamic>> fetchExecutionPackage(Map<String, dynamic> manifest, Map<String, bool> capabilities) async {
    final payload = {
      'manifest': manifest,
      'capabilities': capabilities,
    };
    final response = await _client.post('/execution-package', body: payload);
    if (response.isSuccess && response.data != null) {
      return jsonDecode(response.data!) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch execution package: ${response.message}');
  }
}
