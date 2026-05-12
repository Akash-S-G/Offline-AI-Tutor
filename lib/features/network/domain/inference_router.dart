import '../data/network_state_service.dart';
import 'local_inference_source.dart';

/// Determines how inference should be routed.
enum InferenceRoute {
  /// Use local model only
  local,

  /// Enhance local with backend context
  hybrid,

  /// Use backend primarily
  backend,

  /// Use cached response
  cache,
}

/// Routing decision with metadata.
class RoutingDecision {
  const RoutingDecision({
    required this.route,
    required this.reason,
    this.confidence = 0.0,
    this.fallbackRoute,
  });

  /// Selected route
  final InferenceRoute route;

  /// Why this route was selected
  final String reason;

  /// Confidence in this decision (0-1)
  final double confidence;

  /// Fallback route if primary fails
  final InferenceRoute? fallbackRoute;

  @override
  String toString() => 'RoutingDecision($route: $reason, confidence=$confidence)';
}

/// Routes inference requests based on system state.
class InferenceRouter {
  InferenceRouter({
    required NetworkStateService networkStateService,
    required LocalInferenceSource localInference,
    this.backendConfidenceThreshold = 0.5,
    this.localCacheScoreThreshold = 0.3,
  })  : _networkStateService = networkStateService,
        _localInference = localInference;

  final NetworkStateService _networkStateService;
  final LocalInferenceSource _localInference;
  final double backendConfidenceThreshold;
  final double localCacheScoreThreshold;

  /// Route a question to the appropriate inference engine
  RoutingDecision route(
    String question, {
    required double questionComplexity,
    bool forceLocal = false,
  }) {
    if (forceLocal) {
      return RoutingDecision(
        route: InferenceRoute.local,
        reason: 'Forced local inference',
        confidence: 1.0,
      );
    }

    final quality = _networkStateService.quality;

    // Offline - must use local or cache
    if (quality.name == 'offline') {
      return RoutingDecision(
        route: InferenceRoute.local,
        reason: 'Device is offline',
        confidence: 1.0,
        fallbackRoute: InferenceRoute.cache,
      );
    }

    // Online but no backend - use local
    if (quality.name == 'online') {
      return RoutingDecision(
        route: InferenceRoute.local,
        reason: 'Backend unreachable, using local',
        confidence: 1.0,
        fallbackRoute: InferenceRoute.cache,
      );
    }

    // Backend available - decide based on question complexity
    if (questionComplexity > backendConfidenceThreshold) {
      return RoutingDecision(
        route: InferenceRoute.backend,
        reason: 'Complex question requires backend ($questionComplexity)',
        confidence: questionComplexity,
        fallbackRoute: InferenceRoute.local,
      );
    }

    // Simple question - use local
    return RoutingDecision(
      route: InferenceRoute.local,
      reason: 'Simple question routed to local ($questionComplexity)',
      confidence: 1.0 - questionComplexity,
      fallbackRoute: InferenceRoute.backend,
    );
  }

  /// Check if local model is available
  bool isLocalAvailable() {
    return _localInference.isReady;
  }

  /// Get current network quality
  String getCurrentQuality() {
    return _networkStateService.quality.toString();
  }
}
