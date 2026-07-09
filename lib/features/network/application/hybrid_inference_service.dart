import 'dart:async';

import '../../../config/app_environment.dart';
import '../domain/runtime_backend_url.dart';

import '../data/backend_api_service.dart';
import '../data/backend_health_monitor.dart';
import '../data/network_state_service.dart';
import '../domain/inference_router.dart';
import '../domain/local_inference_source.dart';
import 'educational_complexity_analyzer.dart';
import 'confidence_evaluator.dart';
import 'escalation_coordinator.dart';
import 'intent_detector.dart';
import 'asset_resolver.dart';
import 'session_state.dart';
import 'routing_metrics.dart';
import 'stream_coordinator.dart';
import 'subject_routing_coordinator.dart';
import 'retrieval_diagnostics_tracker.dart';

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
    IntentDetector? intentDetector,
    AssetResolver? assetResolver,
    SubjectRoutingCoordinator? subjectRoutingCoordinator,
    this.localCacheTTLSeconds = 300,
  }) : _localInference = localInference,
       _backendService = backendService,
       _healthMonitor = healthMonitor,
       _router = router,
       _networkState = networkState,
       _confidence = confidenceEvaluator ?? ConfidenceEvaluator(),
       _educationalComplexityAnalyzer =
           educationalComplexityAnalyzer ??
           const EducationalComplexityAnalyzer(),
       _escalationCoordinator =
           escalationCoordinator ?? EscalationCoordinator(),
       _streamCoordinator = streamCoordinator ?? StreamCoordinator(),
       _metrics = metricsTracker ?? RoutingMetricsTracker(),
       _intentDetector = intentDetector ?? IntentDetector(),
       _assetResolver = assetResolver ?? AssetResolver(),
       _subjectRoutingCoordinator =
           subjectRoutingCoordinator ?? const SubjectRoutingCoordinator();

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
  final IntentDetector _intentDetector;
  final AssetResolver _assetResolver;
  final SubjectRoutingCoordinator _subjectRoutingCoordinator;

  final Map<String, _CachedResponse> _responseCache =
      <String, _CachedResponse>{};

  /// Intents whose responses are deterministic and safe to cache.
  static const _cacheableIntents = <TutorIntent>{
    TutorIntent.explainConcept,
    TutorIntent.defineTerm,
    TutorIntent.summarizeTopic,
    TutorIntent.compareConcepts,
    TutorIntent.glossary,
    TutorIntent.keyPoints,
  };

  /// Returns true if responses for [intent] are safe to cache.
  bool _shouldCacheIntent(TutorIntent intent) =>
      _cacheableIntents.contains(intent);

  /// Stream an answer to a question.
  /// Local stream starts first; if confidence is low, backend stream upgrades it.
  Stream<String> streamAnswer(
    String question, {
    String? context,
    String? systemPrompt,
    String? language,
    bool forceLocal = false,
  }) async* {
    final queryInfo = _intentDetector.detect(question);
    final educationalInfo = _educationalComplexityAnalyzer.analyze(question);
    final subjectPreference = _subjectRoutingCoordinator.preferredRouteFor(
      question,
    );
    final decision = _router.route(
      question,
      questionComplexity: queryInfo.confidence > educationalInfo.score
          ? queryInfo.confidence
          : educationalInfo.score,
      forceLocal:
          forceLocal ||
          subjectPreference == 'local' && educationalInfo.score < 0.35,
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
        if (_shouldEscalate(decision, confidence) ||
            escalation.shouldEscalate) {
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
          language: language,
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
          language: language,
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

  /// Stream a tutor-specific answer to a question using the /ai/tutor endpoint.
  Stream<String> streamTutorAnswer(
    String question, {
    required bool backendAvailable,
    required bool hasRelevantLocalContent,
    List<String>? localCurriculumContext,
    int? grade,
    String? subject,
    String? chapter,
    String? language,
    List<String>? conversationHistory,
    String? preparedPrompt,
    SessionState? sessionState,
  }) async* {
    print('[DIAGNOSTICS] ENTERING HybridInferenceService.streamTutorAnswer()');
    print('[DIAGNOSTICS] QUESTION_ID=${DateTime.now().millisecondsSinceEpoch}');
    print('[DIAGNOSTICS] QUESTION=$question');
    print('[DIAGNOSTICS] GRADE=$grade');
    print('[DIAGNOSTICS] SUBJECT=$subject');
    print('[DIAGNOSTICS] CHAPTER=$chapter');
    print('[TUTOR] ACTIVE_BACKEND_URL=${RuntimeBackendUrl().current}');
    print('[TUTOR] BACKEND_AVAILABLE=$backendAvailable');
    print('[TUTOR] HAS_LOCAL_CONTENT=$hasRelevantLocalContent');

    // ── INTENT DETECTION & ASSET RESOLUTION (V2) ──
    final detection = _intentDetector.detect(
      question,
      sessionState: sessionState,
    );

    // Update SessionState from detection result
    sessionState?.updateFromDetection(detection);
    sessionState?.activeChapter ??= chapter;

    // If this is an asset intent, try to resolve from local database
    if (detection.isAssetIntent) {
      final assetResult = await _assetResolver.resolve(
        intent: detection.intent,
        topic: detection.topic,
        chapterId: chapter,
      );
      if (assetResult != null) {
        print('[DIAGNOSTICS] ASSET_RESOLVED=true');
        print('[DIAGNOSTICS] ASSET_SOURCE=${assetResult.metadata}');
        yield assetResult.formattedResponse;
        return;
      } else {
        print('[DIAGNOSTICS] ASSET_RESOLVED=false (falling back to inference)');
      }
    }

    TutorExecutionMode executionMode;
    final localAvailable = _localInference.isReady;

    if (hasRelevantLocalContent && localAvailable) {
      executionMode = TutorExecutionMode.curriculumRag;
    } else {
      if (backendAvailable && _networkState.quality != NetworkQuality.offline) {
        executionMode = TutorExecutionMode.backendRag;
      } else {
        executionMode = TutorExecutionMode.knowledgeFallback;
      }
    }

    RetrievalDiagnosticsTracker.instance.update(
      topic: detection.topic,
      intent: detection.intent.name,
      chunks: localCurriculumContext?.length ?? 0,
      mode: hasRelevantLocalContent ? 'Local RAG' : 'Fallback',
      fallback: hasRelevantLocalContent
          ? ''
          : (backendAvailable ? 'Local missing' : 'Offline'),
      execMode: executionMode.name,
    );

    print('[DIAGNOSTICS] EXECUTION_MODE=${executionMode.name.toUpperCase()}');
    print('[TUTOR] EXECUTION_MODE=${executionMode.name}');
    print('[TUTOR] CONTEXT_CHUNKS=${localCurriculumContext?.length ?? 0}');
    final contextChars = localCurriculumContext?.join('\n\n').length ?? 0;
    print('[TUTOR] LOCAL_CONTEXT_CHARS=$contextChars');
    final startTime = DateTime.now();

    // ── INTENT-AWARE CACHE (Task A) ──
    final cacheAllowed = _shouldCacheIntent(detection.intent);
    print('[CACHE] INTENT=${detection.intent.name}');
    print('[CACHE] ALLOWED=$cacheAllowed');
    if (cacheAllowed) {
      final cached = _getCachedResponse(question);
      if (cached != null) {
        print('[CACHE] HIT=true');
        _metrics.recordLocal();
        yield cached;
        return;
      } else {
        print('[CACHE] MISS=true');
      }
    } else {
      print('[CACHE] BYPASSED=true (dynamic intent)');
    }

    if (executionMode == TutorExecutionMode.backendRag) {
      print('[DIAGNOSTICS] BACKEND_TUTOR_START');
      print('[DIAGNOSTICS] REQUEST_SENT');
      print('[TUTOR] REQUEST_SENT url=${RuntimeBackendUrl().current}/ai/tutor');
      _metrics.recordBackend();
      try {
        final Stream<String> backendStream;

        if (detection.intent == TutorIntent.learningPath ||
            detection.intent == TutorIntent.prerequisiteCheck) {
          print('[DIAGNOSTICS] ROUTING_TO_PLANNER');
          backendStream = _backendService.streamPlannerLesson(
            topic: detection.topic,
            subject: subject,
            grade: grade,
            language: language,
          );
        } else {
          backendStream = _backendService.streamTutorAnswer(
            question: question,
            grade: grade,
            subject: subject,
            chapter: chapter,
            language: language,
            context: localCurriculumContext?.join('\n\n'),
            conversationHistory: conversationHistory,
          );
        }

        await for (final chunk in backendStream) {
          print("[TRACE] HYBRID_RECEIVED=$chunk");
          print("[TRACE] HYBRID_FORWARDING=$chunk");
          yield chunk;
        }
        print('[DIAGNOSTICS] FINAL_EXECUTION_PATH=BACKEND_RAG');
        print('[TUTOR] RESPONSE_RECEIVED execution=BACKEND_RAG');
        final totalMs = DateTime.now().difference(startTime).inMilliseconds;
        print('[DIAGNOSTICS] TOTAL_EXECUTION_TIME_MS=$totalMs');
        return;
      } catch (e) {
        print('[DIAGNOSTICS] BACKEND_TUTOR_FAILED');
        print('[DIAGNOSTICS] BACKEND_ERROR=$e');
        final shouldRetryWithoutContext = _isInvalidCharacterBackendError(e);
        if (shouldRetryWithoutContext && backendAvailable) {
          print('[DIAGNOSTICS] BACKEND_RETRY_WITH_MINIMAL_PAYLOAD');
          try {
            final minimalBackendStream = _backendService.streamTutorAnswer(
              question: question,
              grade: grade,
              subject: subject,
              chapter: chapter,
              language: language,
            );
            await for (final chunk in minimalBackendStream) {
              yield chunk;
            }
            print('[DIAGNOSTICS] FINAL_EXECUTION_PATH=BACKEND_RAG_MINIMAL');
            final totalMs = DateTime.now().difference(startTime).inMilliseconds;
            print('[DIAGNOSTICS] TOTAL_EXECUTION_TIME_MS=$totalMs');
            return;
          } catch (retryError) {
            print('[DIAGNOSTICS] BACKEND_MINIMAL_RETRY_FAILED');
            print('[DIAGNOSTICS] BACKEND_MINIMAL_ERROR=$retryError');
          }
        }
        print('[DIAGNOSTICS] KNOWLEDGE_FALLBACK_START');
        executionMode = TutorExecutionMode.knowledgeFallback;
      }
    }

    if (executionMode == TutorExecutionMode.curriculumRag) {
      print('[DIAGNOSTICS] LOCAL_RAG_START');
      final localBuffer = StringBuffer();
      final contextText = localCurriculumContext?.join('\n\n') ?? '';
      final localPrompt =
          preparedPrompt ??
          '''
You are an offline school tutor. 
Use the following curriculum context to answer the question.
Context:
$contextText

Question: $question
''';
      print('[DIAGNOSTICS] LOCAL_RAG_END');
      print('[DIAGNOSTICS] LOCAL_INFERENCE_START');
      print('[DIAGNOSTICS] PROMPT_TO_NATIVE_LENGTH=${localPrompt.length}');
      print(
        '[DIAGNOSTICS] PROMPT_FIRST_500=${localPrompt.substring(0, localPrompt.length > 500 ? 500 : localPrompt.length)}',
      );

      final localStream = _localInference.streamQuestion(localPrompt);
      var isFirstToken = true;
      try {
        await for (final chunk in localStream) {
          if (isFirstToken) {
            print('[DIAGNOSTICS] LOCAL_FIRST_TOKEN');
            isFirstToken = false;
          }
          localBuffer.write(chunk);
          yield chunk;
        }
      } catch (_) {
        _metrics.recordFailure();
        yield 'Failed to process your question locally. Please try again.';
        return;
      }

      print('[DIAGNOSTICS] LOCAL_STREAM_COMPLETE');
      print('[DIAGNOSTICS] FINAL_EXECUTION_PATH=CURRICULUM_RAG');
      final totalMs = DateTime.now().difference(startTime).inMilliseconds;
      print('[DIAGNOSTICS] TOTAL_EXECUTION_TIME_MS=$totalMs');

      _metrics.recordLocal();
      final text = localBuffer.toString();
      if (text.isNotEmpty) {
        _cacheResponse(question, text, intent: detection.intent);
      }
      return;
    }

    if (executionMode == TutorExecutionMode.knowledgeFallback) {
      print('[DIAGNOSTICS] EXECUTION_MODE=KNOWLEDGE_FALLBACK');
      final localBuffer = StringBuffer();
      final compactContext = (localCurriculumContext ?? const <String>[])
          .take(3)
          .map(_cleanFallbackContextLine)
          .where((line) => line.isNotEmpty)
          .join('\n');
      final localPrompt =
          '''
You are an offline school tutor.
Answer the student's question directly in simple words.
Use the chapter context below only if it helps.
Do not repeat the context headings, labels, or the question.
If the question is just a greeting, respond briefly and invite a chapter question.
Keep the answer concise and educational.

Subject: ${subject ?? 'Unknown'}
Chapter: ${chapter ?? 'Unknown'}
Question: $question
Context:
$compactContext

Answer:
''';
      print('[DIAGNOSTICS] KNOWLEDGE_FALLBACK_PROMPT_BUILT');
      print('[DIAGNOSTICS] LOCAL_INFERENCE_START');
      print('[DIAGNOSTICS] PROMPT_TO_NATIVE_LENGTH=${localPrompt.length}');
      print(
        '[DIAGNOSTICS] PROMPT_FIRST_500=${localPrompt.substring(0, localPrompt.length > 500 ? 500 : localPrompt.length)}',
      );

      final localStream = _localInference.streamQuestion(localPrompt);
      var isFirstToken = true;
      try {
        await for (final chunk in localStream) {
          if (isFirstToken) {
            print('[DIAGNOSTICS] LOCAL_FIRST_TOKEN');
            isFirstToken = false;
          }
          localBuffer.write(chunk);
          yield chunk;
        }
      } catch (_) {
        _metrics.recordFailure();
        yield 'Failed to process your question via fallback. Please try again.';
        return;
      }

      print('[DIAGNOSTICS] LOCAL_STREAM_COMPLETE');
      print('[DIAGNOSTICS] FINAL_EXECUTION_PATH=KNOWLEDGE_FALLBACK');
      final totalMs = DateTime.now().difference(startTime).inMilliseconds;
      print('[DIAGNOSTICS] TOTAL_EXECUTION_TIME_MS=$totalMs');

      _metrics.recordLocal();
      final text = localBuffer.toString();
      if (text.isNotEmpty) {
        _cacheResponse(question, text, intent: detection.intent);
      }
      return;
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

  void _cacheResponse(String question, String response, {TutorIntent? intent}) {
    if (intent != null && !_shouldCacheIntent(intent)) {
      print('[CACHE] STORE_SKIPPED intent=${intent.name} (dynamic)');
      return;
    }
    _responseCache[question.toLowerCase()] = _CachedResponse(
      response: response,
      timestamp: DateTime.now(),
    );
    print(
      '[CACHE] STORED key=${question.toLowerCase().substring(0, question.length > 60 ? 60 : question.length)}',
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

  String _cleanFallbackContextLine(String line) {
    final normalized = line
        .replaceAll(
          RegExp(r'[^\p{L}\p{M}\p{N}\p{P}\p{Zs}\n\r\t]', unicode: true),
          ' ',
        )
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized;
  }

  bool _isInvalidCharacterBackendError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('invalid argument') &&
        message.contains('invalid characters');
  }
}

class _CachedResponse {
  _CachedResponse({required this.response, required this.timestamp});

  final String response;
  final DateTime timestamp;
}
