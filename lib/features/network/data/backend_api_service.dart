import 'dart:convert';

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

  /// Close the backend service
  void close() {
    _httpClient.close();
  }
}
