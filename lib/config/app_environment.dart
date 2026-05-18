import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Structured logging tags for diagnostic output
enum LogTag {
  backend,
  sync,
  discovery,
  routing,
  recovery,
  websocket;

  @override
  String toString() => name.toUpperCase();
}

/// Centralized application environment configuration
/// 
/// This singleton manages all environment variables and network configuration.
/// Loaded from .env file at app startup via flutter_dotenv.
/// 
/// All services should reference this for configuration, not hardcoded values.
class AppEnvironment {
  static final AppEnvironment _instance = AppEnvironment._internal();

  factory AppEnvironment() {
    return _instance;
  }

  AppEnvironment._internal();

  static bool _initialized = false;

  /// Initialize environment from .env file
  /// Must be called before accessing any configuration
  static Future<void> initialize() async {
    if (_initialized) return;
    
    await dotenv.load(fileName: '.env');
    _initialized = true;
    
    _logStartup();
  }

  static void _logStartup() {
    final log = _getLogger('BOOTSTRAP');
    log('Environment initialized');
    log('Backend Gateway: ${AppEnvironment.backendBaseUrl}');
    log('Deployment Mode: ${AppEnvironment.deploymentMode}');
    log('Offline Packs: ${AppEnvironment.enableOfflinePacks}');
    log('Local Inference: ${AppEnvironment.enableLocalInference}');
  }

  // ========================================================================
  // BACKEND CONFIGURATION
  // ========================================================================

  /// Primary backend gateway URL
  static String get backendBaseUrl =>
      _normalizeBackendBaseUrl(
        dotenv.env['BACKEND_BASE_URL'],
      );

  /// Backend gateway port
  static String get backendPort =>
      dotenv.env['BACKEND_PORT'] ?? '8000';

  /// Backend request timeout in seconds
  static int get backendTimeoutSeconds =>
      int.tryParse(dotenv.env['BACKEND_TIMEOUT_SECONDS'] ?? '30') ?? 30;

  /// API key for backend authentication
  static String get backendApiKey =>
      dotenv.env['BACKEND_API_KEY'] ?? 'default-development-key';

  // ========================================================================
  // NGINX GATEWAY ROUTING
  // ========================================================================
  // 
  // All endpoints are routed through the nginx gateway (BACKEND_BASE_URL).
  // The gateway handles service discovery and routing:
  // - GET  /health → health check
  // - POST /ai/chat → AI chat service
  // - POST /ai/tutor → Educational tutor service
  // - POST /rag/search → Vector search (Qdrant)
  // - POST /upload → File upload service
  // - POST /ingest/directory → Content ingestion
  // - GET  /packs/* → Educational pack management
  // - POST /classroom/* → Classroom coordination
  // - etc.
  //
  // Use EndpointBuilder to construct specific endpoints dynamically.
  // NO HARDCODED PORTS (:8000, :8001, :8010, :8020, :6333, etc.).

  // ===== LEGACY COMPATIBILITY ACCESSORS =====
  // These are convenience methods for existing code that references specific services.
  // They all route through the nginx gateway (BACKEND_BASE_URL) now.

  /// Content pipeline service URL (routes through nginx gateway)
  /// Previously: http://172.17.13.112:8002
  /// Now: Routed via BACKEND_BASE_URL/packs/* endpoints
  static String get contentPipelineUrl =>
      backendBaseUrl;

  /// Inference service URL (routes through nginx gateway)
  /// Previously: http://172.17.13.112:8001
  /// Now: Routed via BACKEND_BASE_URL/ai/tutor and local inference
  static String get inferenceUrl =>
      backendBaseUrl;

  /// Qdrant vector database URL (routes through nginx gateway)
  /// Previously: http://172.17.13.112:6333
  /// Now: Routed via BACKEND_BASE_URL/rag/* endpoints
  static String get qdrantUrl =>
      backendBaseUrl;

  /// Sync service URL (routes through nginx gateway)
  /// Previously: http://172.17.13.112:8003
  /// Now: Routed via BACKEND_BASE_URL/sync/* endpoints
  static String get syncUrl =>
      backendBaseUrl;

  /// Classroom coordination URL (routes through nginx gateway)
  /// Previously: http://172.17.13.112:8000/classroom
  /// Now: Routed via BACKEND_BASE_URL/classroom/* endpoints
  static String get classroomUrl =>
      backendBaseUrl;

  /// WebSocket URL (routes through nginx gateway)
  /// Previously: ws://172.17.13.112:8000
  /// Now: Should use BACKEND_BASE_URL with ws/wss protocol
  static String get websocketBaseUrl {
    final url = backendBaseUrl;
    // Convert http/https to ws/wss
    if (url.startsWith('https://')) {
      return url.replaceFirst('https://', 'wss://');
    }
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'ws://');
    }
    return 'ws://$url';
  }

  /// PiHub discovery URL (routes through nginx gateway)
  /// Previously: http://172.17.13.112:8080
  /// Now: Routed via BACKEND_BASE_URL/classroom/devices
  static String get piHubUrl =>
      backendBaseUrl;

  /// PiHub service port (deprecated - all routing through nginx gateway)
  static int get pihubPort => 80;

  // ========================================================================
  // CONNECTIVITY CONFIGURATION
  // ========================================================================

  /// Whether backend connectivity is enabled
  static bool get enableBackend =>
      dotenv.env['ENABLE_BACKEND']?.toLowerCase() != 'false';

  /// Maximum retry attempts for failed connections
  static int get maxRetryAttempts =>
      int.tryParse(dotenv.env['MAX_RETRY_ATTEMPTS'] ?? '3') ?? 3;

  /// Retry delay in seconds
  static int get retryDelaySeconds =>
      int.tryParse(dotenv.env['RETRY_DELAY_SECONDS'] ?? '5') ?? 5;

  /// Exponential backoff multiplier
  static double get backoffMultiplier =>
      double.tryParse(dotenv.env['BACKOFF_MULTIPLIER'] ?? '2.0') ?? 2.0;

  /// Health check interval in seconds
  static int get healthCheckIntervalSeconds =>
      int.tryParse(dotenv.env['HEALTH_CHECK_INTERVAL'] ?? '30') ?? 30;

  // ========================================================================
  // DISCOVERY CONFIGURATION
  // ========================================================================

  /// Enable mDNS service discovery
  static bool get enableMdnsDiscovery =>
      dotenv.env['ENABLE_MDNS_DISCOVERY']?.toLowerCase() != 'false';

  /// mDNS service type
  static String get mdnsServiceType =>
      dotenv.env['MDNS_SERVICE_TYPE'] ?? '_classroom._tcp';

  /// Enable multicast discovery
  static bool get enableMulticastDiscovery =>
      dotenv.env['ENABLE_MULTICAST_DISCOVERY']?.toLowerCase() != 'false';

  /// Multicast group address
  static String get multicastGroup =>
      dotenv.env['MULTICAST_GROUP'] ?? '224.0.0.251';

  /// Multicast port
  static int get multicastPort =>
      int.tryParse(dotenv.env['MULTICAST_PORT'] ?? '5353') ?? 5353;

  // ========================================================================
  // LOGGING & DIAGNOSTICS
  // ========================================================================

  /// Enable structured logging
  static bool get enableStructuredLogging =>
      dotenv.env['ENABLE_STRUCTURED_LOGGING']?.toLowerCase() != 'false';

  /// Log level (debug, info, warning, error)
  static String get logLevel =>
      dotenv.env['LOG_LEVEL'] ?? 'debug';

  /// Which log tags are enabled
  static Set<LogTag> get enabledLogTags {
    final tagsStr = dotenv.env['ENABLED_LOG_TAGS'] ?? '';
    if (tagsStr.isEmpty) return LogTag.values.toSet();

    return tagsStr
        .split(',')
        .map((t) => t.trim().toLowerCase())
        .map((t) {
          try {
            return LogTag.values.firstWhere((tag) => tag.name == t);
          } catch (e) {
            return null;
          }
        })
        .whereType<LogTag>()
        .toSet();
  }

  /// Check if a specific log tag is enabled
  static bool isLogTagEnabled(LogTag tag) => enabledLogTags.contains(tag);

  // ========================================================================
  // OFFLINE BEHAVIOR
  // ========================================================================

  /// Enable local LLM inference when backend unavailable
  static bool get enableLocalInference =>
      dotenv.env['ENABLE_LOCAL_INFERENCE']?.toLowerCase() != 'false';

  /// Enable offline pack distribution
  static bool get enableOfflinePacks =>
      dotenv.env['ENABLE_OFFLINE_PACKS']?.toLowerCase() != 'false';

  /// Automatically sync when backend becomes available
  static bool get autoSyncOnReconnect =>
      dotenv.env['AUTO_SYNC_ON_RECONNECT']?.toLowerCase() != 'false';

  // ========================================================================
  // DEVICE & CLASSROOM CONFIGURATION
  // ========================================================================

  /// Device name for identification
  static String get deviceName =>
      dotenv.env['DEVICE_NAME'] ?? 'android-device';

  /// Unique device ID (auto-generated if not set)
  static String get deviceId =>
      dotenv.env['DEVICE_ID'] ?? _generateDeviceId();

  /// Session timeout in minutes
  static int get sessionTimeoutMinutes =>
      int.tryParse(dotenv.env['SESSION_TIMEOUT_MINUTES'] ?? '120') ?? 120;

  /// Maximum offline duration in hours before session invalidation
  static int get maxOfflineDurationHours =>
      int.tryParse(dotenv.env['MAX_OFFLINE_DURATION_HOURS'] ?? '12') ?? 12;

  // ========================================================================
  // DEPLOYMENT MODE
  // ========================================================================

  /// Deployment mode: production, staging, development
  static String get deploymentMode =>
      dotenv.env['DEPLOYMENT_MODE'] ?? 'production';

  /// Enable debug mode and verbose output
  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  // ========================================================================
  // UTILITY METHODS
  // ========================================================================

  /// Get a logger function for structured logging
  static Function(String) _getLogger(String tag) {
    return (String message) {
      if (enableStructuredLogging) {
        print('[$tag] $message');
      }
    };
  }

  /// Structured log function with tag support
  static void log(String tag, String message) {
    if (!enableStructuredLogging) return;

    try {
      final logTag = LogTag.values.firstWhere(
        (t) => t.name.toUpperCase() == tag.toUpperCase(),
        orElse: () => throw ArgumentError('Invalid log tag'),
      );

      if (isLogTagEnabled(logTag)) {
        print('[${logTag.name.toUpperCase()}] $message');
      }
    } catch (e) {
      if (debugMode) print('[UNKNOWN] $message');
    }
  }

  /// Generate a unique device ID
  static String _generateDeviceId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString().hashCode.abs();
    String result = '';
    for (int i = 0; i < 8; i++) {
      result += chars[(random + i) % chars.length];
    }
    return 'dev-$result';
  }

  /// Get all configuration as a map (for debugging)
  static Map<String, dynamic> toMap() => {
    'backendBaseUrl': backendBaseUrl,
    'backendTimeoutSeconds': backendTimeoutSeconds,
    'maxRetryAttempts': maxRetryAttempts,
    'retryDelaySeconds': retryDelaySeconds,
    'backoffMultiplier': backoffMultiplier,
    'enableBackend': enableBackend,
    'enableOfflinePacks': enableOfflinePacks,
    'enableLocalInference': enableLocalInference,
    'autoSyncOnReconnect': autoSyncOnReconnect,
    'deploymentMode': deploymentMode,
    'deviceName': deviceName,
    'deviceId': deviceId,
    'healthCheckIntervalSeconds': healthCheckIntervalSeconds,
  };

  static String _normalizeBackendBaseUrl(String? rawValue) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) {
      // Default to production configuration
      return 'http://10.28.73.193';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      // Invalid URI, use default
      return 'http://10.28.73.193';
    }

    // Return the URI as-is (nginx gateway manages all ports)
    return uri.toString();
  }

  /// Print current configuration (debug)
  static void printConfiguration() {
    print('=== APP ENVIRONMENT CONFIGURATION ===');
    toMap().forEach((key, value) {
      print('$key: $value');
    });
    print('=====================================');
  }
}
