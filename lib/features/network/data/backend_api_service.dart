import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'backend_availability_cache.dart';
import '../../../config/app_environment.dart';
import '../domain/backend_config.dart';
import '../domain/backend_response.dart';
import 'backend_http_client.dart';

/// Main service for backend API communication.
/// Handles all interactions with distributed backend infrastructure.
class BackendApiService {
  BackendApiService({
    required BackendConfig config,
    BackendHttpClient? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? BackendHttpClient(config: config);

  final BackendConfig _config;
  final BackendHttpClient _httpClient;

  /// Check if backend is configured
  bool get isConfigured => _config.isValid;

  /// Get backend configuration (without sensitive data)
  String get configInfo => _config.toString();

  /// Health check - verify backend is reachable
  Future<BackendResponse<Map<String, dynamic>>> healthCheck() async {
    final response = await _httpClient.get('/health');

    if (response.isFailure) {
      return BackendResponse.failure(
        message: response.message ?? 'Health check failed',
        statusCode: response.statusCode,
        error: response.error,
      );
    }

    try {
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      return BackendResponse.success(data);
    } catch (error) {
      return BackendResponse.failure(
        message: 'Failed to parse health check response',
        error: error,
      );
    }
  }

  /// Fast check if backend is available
  Future<bool> isBackendAvailable() async {
    final cache = BackendAvailabilityCache();
    final cached = cache.cachedStatus;
    if (cached != null) {
      print('[DIAGNOSTICS] BACKEND_HEALTH_CHECK_CACHED=$cached');
      return cached;
    }

    try {
      print('[DIAGNOSTICS] BACKEND_HEALTH_CHECK_START');
      print('[DIAGNOSTICS] HEALTH_CHECK_URL=${_config.baseUrl}/health');
      final response = await _httpClient.get(
        '/health',
        maxRetries: 0,
        timeout: const Duration(seconds: 3),
      );
      final available = response.isSuccess;
      print('[DIAGNOSTICS] BACKEND_HEALTH_CHECK_END');
      print('[DIAGNOSTICS] BACKEND_AVAILABLE=$available');
      cache.updateStatus(available);
      return available;
    } catch (e) {
      print('[DIAGNOSTICS] BACKEND_HEALTH_CHECK_END (FAILED)');
      print('[DIAGNOSTICS] BACKEND_ERROR=$e');
      cache.updateStatus(false);
      return false;
    }
  }

  /// Generate an answer using backend AI
  Future<BackendResponse<String>> generateAnswer({
    required String question,
    String? context,
    String? systemPrompt,
    int maxTokens = 512,
  }) async {
    final body = <String, dynamic>{
      'question': question,
      'max_tokens': maxTokens,
      'stream': false,
    };

    if (context != null && context.isNotEmpty) {
      body['context'] = context;
    }
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system_prompt'] = systemPrompt;
    }

    final response = await _httpClient.post(
      '/ai/chat',
      body: body,
    );

    if (response.isFailure) {
      return BackendResponse.failure(
        message: response.message ?? 'Failed to generate answer',
        statusCode: response.statusCode,
        error: response.error,
      );
    }

    try {
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final answer = data['answer'] as String? ?? '';
      return BackendResponse.success(answer);
    } catch (error) {
      return BackendResponse.failure(
        message: 'Failed to parse answer response',
        error: error,
      );
    }
  }

  /// Stream an answer from backend AI
  Stream<String> streamAnswer({
    required String question,
    String? context,
    String? systemPrompt,
    int maxTokens = 512,
  }) async* {
    AppEnvironment.log(
      'BACKEND',
      'Starting streaming answer request',
    );
    
    final body = <String, dynamic>{
      'question': question,
      'max_tokens': maxTokens,
      'stream': true,
    };

    if (context != null && context.isNotEmpty) {
      body['context'] = context;
    }
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system_prompt'] = systemPrompt;
    }

    try {
      await for (final chunk in _httpClient.stream('/ai/chat/stream', body: body)) {
        final trimmed = chunk.trim();
        if (trimmed.isEmpty || trimmed.startsWith(':')) {
          continue;
        }

        if (trimmed.startsWith('data:')) {
          final jsonStr = trimmed.substring(5).trim();
          if (jsonStr == '[DONE]') {
            AppEnvironment.log(
              'BACKEND',
              'Stream completed',
            );
            break;
          }
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            final token = data['token'] as String? ?? '';
            if (token.isNotEmpty) {
              yield token;
            }
          } catch (_) {
            // Skip malformed JSON
            continue;
          }
        } else {
          yield trimmed;
        }
      }
    } catch (error) {
      AppEnvironment.log(
        'BACKEND',
        'Stream error: $error',
      );
      rethrow;
    }
  }

  /// Retrieve documents for RAG
  Future<BackendResponse<List<String>>> retrieveDocuments({
    required String query,
    int limit = 5,
  }) async {
    final response = await _httpClient.post(
      '/rag/retrieve',
      body: <String, dynamic>{
        'query': query,
        'limit': limit,
      },
    );

    if (response.isFailure) {
      return BackendResponse.failure(
        message: response.message ?? 'Failed to retrieve documents',
        statusCode: response.statusCode,
        error: response.error,
      );
    }

    try {
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final documents = (data['documents'] as List?)?.cast<String>() ?? [];
      return BackendResponse.success(documents);
    } catch (error) {
      return BackendResponse.failure(
        message: 'Failed to parse documents response',
        error: error,
      );
    }
  }

  /// List remote packs from backend
  Future<BackendResponse<List<dynamic>>> listPacks() async {
    final response = await _httpClient.get('/packs');
    if (response.isFailure) {
      return BackendResponse.failure(
        message: response.message ?? 'Failed to list packs',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    try {
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final packs = data['packs'] as List<dynamic>? ?? [];
      return BackendResponse.success(packs);
    } catch (error) {
      return BackendResponse.failure(
        message: 'Failed to parse packs response',
        error: error,
      );
    }
  }

  /// Get pack manifest
  Future<BackendResponse<Map<String, dynamic>>> getPackManifest(String id) async {
    final response = await _httpClient.get('/packs/$id/manifest');
    if (response.isFailure) {
      return BackendResponse.failure(
        message: response.message ?? 'Failed to get pack manifest',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    try {
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      return BackendResponse.success(data);
    } catch (error) {
      return BackendResponse.failure(
        message: 'Failed to parse manifest response',
        error: error,
      );
    }
  }

  /// Download pack archive
  Future<String> downloadPack(String id, String savePath) async {
    final uri = Uri.parse('${_config.baseUrl}/packs/$id/download');
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer ${_config.apiKey}');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Pack download failed with HTTP ${response.statusCode}');
      }
      final file = File(savePath);
      await response.pipe(file.openWrite());
      return savePath;
    } finally {
      client.close(force: true);
    }
  }

  /// Stream an answer from backend AI Tutor
  Stream<String> streamTutorAnswer({
    required String question,
    int? grade,
    String? subject,
    String? chapter,
    String? language,
    List<String>? conversationHistory,
  }) async* {
    print('[DIAGNOSTICS] ENTERING BackendApiService.streamTutorAnswer()');
    print('[DIAGNOSTICS] REQUEST_START (BACKEND)');
    AppEnvironment.log(
      'BACKEND',
      'Starting streaming tutor answer request',
    );
    

    final body = <String, dynamic>{
      'question': question,
      'stream': true,
    };

    if (grade != null) body['grade'] = grade;
    if (subject != null && subject.isNotEmpty) body['subject'] = subject;
    if (chapter != null && chapter.isNotEmpty) body['chapter'] = chapter;
    if (language != null && language.isNotEmpty) body['language'] = language;
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      body['conversationHistory'] = conversationHistory;
    }

    try {
      final startTime = DateTime.now();
      print('[DIAGNOSTICS] REQUEST_SENT (BACKEND)');
      var isFirstToken = true;
      await for (final chunk in _httpClient.stream('/ai/tutor', body: body)) {
        if (isFirstToken) {
          final firstTokenMs = DateTime.now().difference(startTime).inMilliseconds;
          print('[DIAGNOSTICS] BACKEND_NETWORK_MS=$firstTokenMs');
        }
        final trimmed = chunk.trim();
        if (trimmed.isEmpty || trimmed.startsWith(':')) {
          continue;
        }

        if (trimmed.startsWith('data:')) {
          final jsonStr = trimmed.substring(5).trim();
          if (jsonStr == '[DONE]') {
            AppEnvironment.log(
              'BACKEND',
              'Tutor stream completed',
            );
            break;
          }
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            final token = data['token'] as String? ?? data['answer'] as String? ?? '';
            if (token.isNotEmpty) {
              if (isFirstToken) {
                print('[DIAGNOSTICS] BACKEND_FIRST_TOKEN');
                final firstTokenTotal = DateTime.now().difference(startTime).inMilliseconds;
                print('[DIAGNOSTICS] BACKEND_FIRST_TOKEN_MS=$firstTokenTotal');
                isFirstToken = false;
              }
              yield token;
            }
          } catch (_) {
            continue;
          }
        } else {
          yield trimmed;
        }
      }
      final totalMs = DateTime.now().difference(startTime).inMilliseconds;
      print('[DIAGNOSTICS] BACKEND_STREAM_COMPLETE');
      print('[DIAGNOSTICS] BACKEND_TOTAL_MS=$totalMs');
    } catch (error) {
      AppEnvironment.log(
        'BACKEND',
        'Tutor stream error: $error',
      );
      rethrow;
    }
  }

  /// Close the backend service
  void close() {
    _httpClient.close();
  }
}
