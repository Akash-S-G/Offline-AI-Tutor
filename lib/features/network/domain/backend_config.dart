import '../../../config/app_environment.dart';

/// Configuration for backend connectivity.
class BackendConfig {
  const BackendConfig({
    required this.baseUrl,
    required this.apiKey,
    this.connectTimeoutSeconds = 10,
    this.requestTimeoutSeconds = 30,
    this.maxRetries = 3,
    this.retryDelayMillis = 500,
    this.backoffMultiplier = 1.5,
  });

  /// Backend base URL (e.g., 'https://api.example.com')
  final String baseUrl;

  /// API authentication key
  final String apiKey;

  /// Connection timeout in seconds
  final int connectTimeoutSeconds;

  /// Request timeout in seconds
  final int requestTimeoutSeconds;

  /// Maximum number of retries for failed requests
  final int maxRetries;

  /// Initial delay between retries in milliseconds
  final int retryDelayMillis;

  /// Backoff multiplier for exponential retry delay
  final double backoffMultiplier;

  /// Whether configuration is valid
  bool get isValid => baseUrl.isNotEmpty && apiKey.isNotEmpty;

  /// Create from centralized environment configuration
  static BackendConfig? fromEnvironment() {
    // Use AppEnvironment for all configuration
    final baseUrl = AppEnvironment.backendBaseUrl;
    final apiKey = AppEnvironment.backendApiKey;
    final timeoutSeconds = AppEnvironment.backendTimeoutSeconds;
    final maxRetries = AppEnvironment.maxRetryAttempts;
    final retryDelay = (AppEnvironment.retryDelaySeconds * 1000).toInt();
    final backoff = AppEnvironment.backoffMultiplier;

    if (baseUrl.isEmpty || apiKey.isEmpty) {
      return null;
    }

    AppEnvironment.log(
      'BACKEND',
      'Initialized backend config: $baseUrl',
    );

    return BackendConfig(
      baseUrl: baseUrl,
      apiKey: apiKey,
      connectTimeoutSeconds: timeoutSeconds,
      requestTimeoutSeconds: timeoutSeconds,
      maxRetries: maxRetries,
      retryDelayMillis: retryDelay,
      backoffMultiplier: backoff,
    );
  }

  @override
  String toString() => 'BackendConfig(baseUrl=$baseUrl, apiKey=${apiKey.substring(0, 8)}...)';
}
