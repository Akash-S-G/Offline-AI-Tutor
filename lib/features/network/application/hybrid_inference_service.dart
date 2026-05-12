import 'dart:async';

import '../data/backend_api_service.dart';
import '../data/backend_health_monitor.dart';
import '../data/network_state_service.dart';
import '../domain/inference_router.dart';
import '../domain/local_inference_source.dart';
import 'educational_complexity_analyzer.dart';
import 'confidence_evaluator.dart';
import 'escalation_coordinator.dart';
import 'query_classifier.dart';
import 'routing_metrics.dart';
import 'stream_coordinator.dart';
import 'subject_routing_coordinator.dart';

/// Hybrid inference engine coordinating local and backend inference.
class HybridInferenceService {
  HybridInferenceService({
    required LocalInferenceSource localInference,
    required BackendApiService backendService,
    required BackendHealthMonitor healthMonitor,
    required InferenceRouter router,
    required NetworkStateService networkState,
    ConfidenceEvaluator? confidenceEvaluator,
    EducationalComplexityAnalyzer? educationalComplexityAnalyzer,
    EscalationCoordinator? escalationCoordinator,
    StreamCoordinator? streamCoordinator,
    RoutingMetricsTracker? metricsTracker,
    QueryClassifier? queryClassifier,
    SubjectRoutingCoordinator? subjectRoutingCoordinator,
    this.localCacheTTLSeconds = 604800,
  })  : _localInference = localInference,
        _backendService = backendService,
        _healthMonitor = healthMonitor,
        _router = router,
        _networkState = networkState,
        _confidence = confidenceEvaluator ?? ConfidenceEvaluator(),
      _educationalComplexityAnalyzer = educationalComplexityAnalyzer ?? const EducationalComplexityAnalyzer(),
      _escalationCoordinator = escalationCoordinator ?? EscalationCoordinator(),
        _streamCoordinator = streamCoordinator ?? StreamCoordinator(),
        _metrics = metricsTracker ?? RoutingMetricsTracker(),
      _queryClassifier = queryClassifier ?? QueryClassifier(),
      _subjectRoutingCoordinator = subjectRoutingCoordinator ?? const SubjectRoutingCoordinator();

  final LocalInferenceSource _localInference;
  final BackendApiService _backendService;
  final BackendHealthMonitor _healthMonitor;
  final InferenceRouter _router;
  final NetworkStateService _networkState;
  final int localCacheTTLSeconds;

  final ConfidenceEvaluator _confidence;
  final EducationalComplexityAnalyzer _educationalComplexityAnalyzer;
  final EscalationCoordinator _escalationCoordinator;
  final StreamCoordinator _streamCoordinator;
  final RoutingMetricsTracker _metrics;
  final QueryClassifier _queryClassifier;
  final SubjectRoutingCoordinator _subjectRoutingCoordinator;

  final Map<String, _CachedResponse> _responseCache = <String, _CachedResponse>{};

  /// Stream an answer to a question.
  /// Local stream starts first; if confidence is low, backend stream upgrades it.
  Stream<String> streamAnswer(
    String question, {
    String? context,
    String? systemPrompt,
    bool forceLocal = false,
  }) async* {
    final queryInfo = _queryClassifier.classify(question);
    final educationalInfo = _educationalComplexityAnalyzer.analyze(question);
    final subjectPreference = _subjectRoutingCoordinator.preferredRouteFor(question);
    final decision = _router.route(
      question,
      questionComplexity: queryInfo.complexity > educationalInfo.score
          ? queryInfo.complexity
          : educationalInfo.score,
      forceLocal: forceLocal || subjectPreference == 'local' && educationalInfo.score < 0.35,
    );

    if (decision.route == InferenceRoute.cache) {
      final cached = _getCachedResponse(question);
      if (cached != null) {
        _metrics.recordLocal();
        yield cached;
        return;
      }
    }

    final localBuffer = StringBuffer();
    final localStream = _localInference.streamQuestion(question);
    var escalated = false;

    try {
      await for (final chunk in localStream) {
        localBuffer.write(chunk);
        yield chunk;

        final confidence = _confidence.evaluate(localBuffer.toString());
        final escalation = _escalationCoordinator.evaluate(
          question: question,
          partialAnswer: localBuffer.toString(),
          score: confidence,
        );
        if (_shouldEscalate(decision, confidence) || escalation.shouldEscalate) {
          escalated = true;
          _metrics.recordEscalation();
          await _streamCoordinator.stopActive();
          await _localInference.stopGeneration();
          break;
        }
      }

      if (escalated) {
        _metrics.recordBackend();
        final backendStream = _backendService.streamAnswer(
          question: question,
          context: context,
          systemPrompt: systemPrompt,
        );
        await for (final chunk in backendStream) {
          yield chunk;
        }
      } else {
        _metrics.recordLocal();
        final text = localBuffer.toString();
        if (text.isNotEmpty) {
          _cacheResponse(question, text);
        }
      }
    } catch (_) {
      _metrics.recordFailure();
      if (decision.fallbackRoute == InferenceRoute.backend) {
        final backendStream = _backendService.streamAnswer(
          question: question,
          context: context,
          systemPrompt: systemPrompt,
        );
        await for (final chunk in backendStream) {
          yield chunk;
        }
      } else {
        final cached = _getCachedResponse(question);
        if (cached != null) {
          yield cached;
        } else {
          yield 'Failed to process your question. Please try again.';
        }
      }
    }
  }

  bool _shouldEscalate(RoutingDecision decision, ConfidenceScore confidence) {
    if (decision.route == InferenceRoute.backend) {
      return true;
    }
    if (decision.route == InferenceRoute.hybrid) {
      return confidence.score < _confidence.minAcceptable;
    }
    return confidence.score < 0.35;
  }

  Future<void> stopGeneration() async {
    await _streamCoordinator.stopActive();
    await _localInference.stopGeneration();
  }

  Map<String, dynamic> getRoutingStats() {
    return <String, dynamic>{
      ..._metrics.snapshot(),
      'backend_health': _healthMonitor.currentHealth.toString(),
      'network_quality': _networkState.quality.toString(),
      'local_available': _router.isLocalAvailable(),
    };
  }

  void close() {
    _responseCache.clear();
  }

  void _cacheResponse(String question, String response) {
    _responseCache[question.toLowerCase()] = _CachedResponse(
      response: response,
      timestamp: DateTime.now(),
    );
  }

  String? _getCachedResponse(String question) {
    final key = question.toLowerCase();
    final cached = _responseCache[key];
    if (cached == null) {
      return null;
    }

    final age = DateTime.now().difference(cached.timestamp).inSeconds;
    if (age > localCacheTTLSeconds) {
      _responseCache.remove(key);
      return null;
    }

    return cached.response;
  }
}

class _CachedResponse {
  _CachedResponse({
    required this.response,
    required this.timestamp,
  });

  final String response;
  final DateTime timestamp;
}
