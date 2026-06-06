import 'dart:convert';
import 'dart:io';


import '../../network/domain/backend_config.dart';
import 'models/experiment_run_dto.dart';
import 'models/experiment_event_dto.dart';
import 'models/analytics_dto.dart';

class ExperimentApiService {
  final BackendConfig _config;

  ExperimentApiService(this._config);

  Future<void> createRun(ExperimentRunDto run) async {
    await _post('/experiment-runs', run.toJson());
  }

  Future<void> appendEvents(String runId, List<ExperimentEventDto> events) async {
    final payload = {'events': events.map((e) => e.toJson()).toList()};
    await _post('/experiment-runs/$runId/events', payload);
  }

  Future<void> completeRun(String runId, Map<String, dynamic> metrics) async {
    await _post('/experiment-runs/$runId/complete', {'metrics': metrics});
  }

  Future<ExperimentRunDto?> fetchRun(String runId) async {
    final data = await _get('/experiment-runs/$runId');
    if (data == null) return null;
    return ExperimentRunDto.fromJson(data);
  }

  Future<List<ExperimentRunDto>> fetchStudentHistory(String studentId) async {
    final data = await _get('/experiment-runs/student/$studentId');
    if (data == null || data['runs'] == null) return [];
    return (data['runs'] as List).map((r) => ExperimentRunDto.fromJson(r)).toList();
  }

  Future<AnalyticsDto?> fetchAnalytics(String studentId) async {
    final data = await _get('/analytics/student/$studentId');
    if (data == null) return null;
    return AnalyticsDto.fromJson(data);
  }

  Future<Map<String, dynamic>?> fetchExecutionDefinition(String manifestId) async {
    return await _get('/manifest/templates/$manifestId/execution');
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    if (!_config.isValid) throw Exception('Backend config invalid');
    final uri = Uri.parse('${_config.baseUrl}$path');
    final client = HttpClient();
    client.connectionTimeout = Duration(seconds: _config.connectTimeoutSeconds);
    
    try {
      final request = await client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer ${_config.apiKey}');
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(body));
      
      final response = await request.close().timeout(Duration(seconds: _config.requestTimeoutSeconds));
      if (response.statusCode >= 400) {
        throw HttpException('HTTP ${response.statusCode} on POST $path');
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>?> _get(String path) async {
    if (!_config.isValid) throw Exception('Backend config invalid');
    final uri = Uri.parse('${_config.baseUrl}$path');
    final client = HttpClient();
    client.connectionTimeout = Duration(seconds: _config.connectTimeoutSeconds);
    
    try {
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer ${_config.apiKey}');
      
      final response = await request.close().timeout(Duration(seconds: _config.requestTimeoutSeconds));
      if (response.statusCode >= 400) {
        throw HttpException('HTTP ${response.statusCode} on GET $path');
      }
      
      final responseBody = await response.transform(utf8.decoder).join();
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }
}
