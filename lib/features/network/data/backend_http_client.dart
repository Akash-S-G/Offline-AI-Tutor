import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/backend_config.dart';
import '../domain/backend_response.dart';

/// Low-level HTTP client for backend communication.
class BackendHttpClient {
  BackendHttpClient({
    required BackendConfig config,
    HttpClient? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? HttpClient();

  final BackendConfig _config;
  final HttpClient _httpClient;

  /// Send GET request
  Future<BackendResponse<String>> get(
    String path, {
    Map<String, String>? headers,
    int? maxRetries,
    Duration? timeout,
  }) async {
    return _executeRequest(
      method: 'GET',
      path: path,
      headers: headers,
      maxRetries: maxRetries,
      timeout: timeout,
    );
  }

  /// Send POST request
  Future<BackendResponse<String>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    return _executeRequest(
      method: 'POST',
      path: path,
      body: jsonEncode(body),
      headers: headers,
    );
  }

  /// Send streaming request
  Stream<String> stream(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async* {
    try {
      final request = await _prepareRequest(
        method: 'POST',
        path: path,
        headers: headers,
      );

      request.write(jsonEncode(body));
      final response = await request.close();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      await for (final chunk in response.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.trim().isNotEmpty) {
          yield chunk;
        }
      }
    } catch (error) {
      rethrow;
    }
  }

  /// Execute a single request with retries
  Future<BackendResponse<String>> _executeRequest({
    required String method,
    required String path,
    String? body,
    Map<String, String>? headers,
    int? maxRetries,
    Duration? timeout,
  }) async {
    Object? lastError;
    int? lastStatusCode;
    
    final retries = maxRetries ?? _config.maxRetries;
    final requestTimeout = timeout ?? Duration(seconds: _config.requestTimeoutSeconds);
    final connectTimeout = timeout ?? Duration(seconds: _config.connectTimeoutSeconds);

    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final request = await _prepareRequest(
          method: method,
          path: path,
          headers: headers,
          timeout: connectTimeout,
        );

        if (body != null) {
          request.write(body);
        }

        final response = await request.close().timeout(requestTimeout);
        lastStatusCode = response.statusCode;

        if (response.statusCode < 200 || response.statusCode >= 300) {
          lastError = HttpException('HTTP ${response.statusCode}');
          if (attempt < retries) {
            await _delayBeforeRetry(attempt);
            continue;
          }
          return BackendResponse.failure(
            message: 'HTTP error: ${response.statusCode}',
            statusCode: response.statusCode,
            error: lastError,
          );
        }

        final responseBody = await utf8.decodeStream(response);
        return BackendResponse.success(
          responseBody,
          statusCode: response.statusCode,
        );
      } catch (error) {
        lastError = error;
        if (attempt < retries && _shouldRetry(error)) {
          await _delayBeforeRetry(attempt);
          continue;
        }
        return BackendResponse.failure(
          message: error.toString(),
          statusCode: lastStatusCode,
          error: error,
        );
      }
    }

    return BackendResponse.failure(
      message: 'Request failed after $retries retries: $lastError',
      error: lastError,
    );
  }

  /// Prepare an HTTP request with headers and authentication
  Future<HttpClientRequest> _prepareRequest({
    required String method,
    required String path,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('${_config.baseUrl}$path');
    final request = await _httpClient
        .openUrl(method, uri)
        .timeout(timeout ?? Duration(seconds: _config.connectTimeoutSeconds));

    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer ${_config.apiKey}');
    request.headers.set('User-Agent', 'DistributedEducationalClient/1.0');

    headers?.forEach((key, value) {
      request.headers.set(key, value);
    });

    return request;
  }

  /// Whether an error is retryable
  bool _shouldRetry(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error is HttpException) ||
        error is HandshakeException;
  }

  /// Delay before retry with exponential backoff
  Future<void> _delayBeforeRetry(int attemptNumber) async {
    final delayMs = (_config.retryDelayMillis *
            pow(_config.backoffMultiplier, attemptNumber).toDouble())
        .toInt();
    await Future<void>.delayed(Duration(milliseconds: delayMs));
  }

  /// Close the HTTP client
  void close() {
    _httpClient.close();
  }
}

num pow(num base, num exponent) {
  // Simple power function
  if (exponent == 0) return 1;
  if (exponent == 1) return base;
  num result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
