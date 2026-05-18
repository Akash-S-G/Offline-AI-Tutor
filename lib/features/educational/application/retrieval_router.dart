import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'local_search_service.dart';
import '../models/educational_models.dart';
import '../../../config/app_environment.dart';

/// Routing decision for retrieval: local vs backend
enum RetrievalRoute {
  local, // Use local results
  backend, // Escalate to backend
  hybrid, // Try local first, then backend
  offline, // Only local (no backend access)
}

/// Result of retrieval routing decision
class RoutingDecision {
  final RetrievalRoute route;
  final double confidence; // 0.0-1.0, represents confidence in local results
  final String reason; // Why this route was chosen
  final List<SearchResult> localResults; // Local search results (if any)

  RoutingDecision({
    required this.route,
    required this.confidence,
    required this.reason,
    required this.localResults,
  });

  bool get useLocal => route == RetrievalRoute.local || route == RetrievalRoute.offline;
  bool get useBackend =>
      route == RetrievalRoute.backend || route == RetrievalRoute.hybrid;
}

/// Intelligent retrieval router that decides between local and backend
/// 
/// Decision factors:
/// - Local search result quality (relevance, count)
/// - Network connectivity
/// - Backend service availability
/// - User preferences and feature flags
class RetrievalRouter {
  static final RetrievalRouter _instance = RetrievalRouter._internal();

  factory RetrievalRouter() {
    return _instance;
  }

  RetrievalRouter._internal();

  final LocalSearchService _searchService = LocalSearchService();

  /// Primary entry point: route a query to optimal data source
  /// 
  /// Query flow:
  /// 1. Execute local search
  /// 2. Calculate confidence in local results
  /// 3. Consider network state and feature flags
  /// 4. Return routing decision with results
  Future<RoutingDecision> routeQuery(String query) async {
    AppEnvironment.log('SYNC', '[RoutingRouter] Routing query: "$query"');

    try {
      // Step 1: Local search
      final localResults = await _searchService.search(query);
      final confidence = await _searchService.calculateSearchConfidence(query, localResults);

      // Step 2: Check feature flags
      final offlineMode = dotenv.env['ENABLE_OFFLINE_PACKS']?.toLowerCase() == 'true';
      final backendEnabled = dotenv.env['ENABLE_BACKEND']?.toLowerCase() == 'true';

      // Step 3: Route decision logic
      final decision = _makeRoutingDecision(
        query,
        localResults,
        confidence,
        offlineMode,
        backendEnabled,
      );

      AppEnvironment.log(
        'SYNC',
        '[RoutingRouter] Routed to ${decision.route.name}: ${decision.reason}',
      );

      return decision;
    } catch (e) {
      AppEnvironment.log('SYNC', '[RoutingRouter] Error routing query: $e');

      // Fall back to local-only on error
      return RoutingDecision(
        route: RetrievalRoute.offline,
        confidence: 0.0,
        reason: 'Error during routing - using local only',
        localResults: [],
      );
    }
  }

  /// Internal routing decision logic
  RoutingDecision _makeRoutingDecision(
    String query,
    List<SearchResult> localResults,
    double confidence,
    bool offlineMode,
    bool backendEnabled,
  ) {
    // Confidence thresholds
    const highConfidenceThreshold = 0.75;
    const mediumConfidenceThreshold = 0.5;

    // If offline mode is enabled, always use local
    if (offlineMode) {
      return RoutingDecision(
        route: RetrievalRoute.offline,
        confidence: confidence,
        reason: 'Offline mode enabled - using local results only',
        localResults: localResults,
      );
    }

    // If backend is disabled, use local
    if (!backendEnabled) {
      return RoutingDecision(
        route: RetrievalRoute.local,
        confidence: confidence,
        reason: 'Backend disabled in configuration',
        localResults: localResults,
      );
    }

    // High confidence in local results
    if (confidence >= highConfidenceThreshold && localResults.isNotEmpty) {
      return RoutingDecision(
        route: RetrievalRoute.local,
        confidence: confidence,
        reason: 'High confidence in local results (${(confidence * 100).toStringAsFixed(0)}%)',
        localResults: localResults,
      );
    }

    // Medium confidence - use hybrid (local first, then backend)
    if (confidence >= mediumConfidenceThreshold && localResults.isNotEmpty) {
      return RoutingDecision(
        route: RetrievalRoute.hybrid,
        confidence: confidence,
        reason: 'Medium confidence - will use local results and optionally enhance with backend',
        localResults: localResults,
      );
    }

    // Low confidence - escalate to backend
    if (localResults.isEmpty) {
      return RoutingDecision(
        route: RetrievalRoute.backend,
        confidence: 0.0,
        reason: 'No local results found - escalating to backend',
        localResults: [],
      );
    }

    // Default: escalate to backend for better results
    return RoutingDecision(
      route: RetrievalRoute.backend,
      confidence: confidence,
      reason: 'Low confidence in local results - escalating to backend',
      localResults: localResults,
    );
  }

  /// Check if a query should be answered from local cache
  bool shouldUseLocalResults(double confidence) {
    return confidence >= 0.7; // 70% confidence threshold
  }

  /// Get chapter context for a search result
  /// Useful for LLM-based responses
  Future<ChapterContextData?> getContextForResult(SearchResult result) async {
    try {
      // If result is a concept, get its parent chapter
      if (result.type == 'concept') {
        // TODO: Query to get chapter ID from concept ID
        return null;
      }

      // If result is a chapter, get all its concepts
      if (result.type == 'chapter') {
        final concepts = <ConceptModel>[];
        // TODO: Load concepts for chapter
        return ChapterContextData(
          chapter: ChapterModel(
            id: int.tryParse(result.id),
            subjectId: 0, // TODO: Determine from database
            name: result.title,
            sequenceNumber: 0,
            summary: result.content,
            content: null,
            estimatedReadingMinutes: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          concepts: concepts,
          estimatedTokens: 0,
        );
      }

      return null;
    } catch (e) {
      AppEnvironment.log('SYNC', '[RoutingRouter] Error getting context: $e');
      return null;
    }
  }

  /// Analytics: log retrieval decision for monitoring
  void logRetrievalDecision(RoutingDecision decision, Duration responseTime) {
    AppEnvironment.log(
      'SYNC',
      '[RoutingAnalytics] Route=${decision.route.name}, Confidence=${(decision.confidence * 100).toStringAsFixed(0)}%, Time=${responseTime.inMilliseconds}ms, Results=${decision.localResults.length}',
    );
  }
}

/// Extension on RetrievalRouter for backend integration
extension BackendEscalation on RetrievalRouter {
  /// Escalate query to backend RAG service
  /// 
  /// Called when local confidence is insufficient
  /// Returns backend results to be merged with local results
  Future<List<SearchResult>> escalateToBackend(String query) async {
    try {
      AppEnvironment.log('SYNC', '[RoutingRouter] Escalating to backend: "$query"');

      // TODO: Call backend endpoint using EndpointBuilder.ragSearch
      // const backendUrl = EndpointBuilder.fromEnvironment().ragSearch;
      // final response = await http.post(
      //   Uri.parse(backendUrl),
      //   body: {'query': query},
      // );
      // Parse and return results

      return [];
    } catch (e) {
      AppEnvironment.log('SYNC', '[RoutingRouter] Backend escalation failed: $e');
      return [];
    }
  }
}
