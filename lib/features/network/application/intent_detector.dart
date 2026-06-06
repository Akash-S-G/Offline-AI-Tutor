import 'session_state.dart';

/// Production-grade educational intent enum.
///
/// Every user message is classified into exactly one intent.
/// Asset intents (flashcards, quiz, glossary, etc.) bypass the LLM entirely.
/// Conversational intents (explain, solve, etc.) route through RAG + LLM.
enum TutorIntent {
  // ── Conceptual understanding ──
  explainConcept,
  summarizeTopic,
  defineTerm,
  giveExample,
  compareConcepts,

  // ── Problem solving ──
  solveProblem,
  guidedSolution,
  giveHint,
  practiceQuestion,
  generateWorksheet,

  // ── Assessment ──
  startQuiz,
  continueQuiz,
  evaluateAnswer,
  revisionTest,

  // ── Structured assets ──
  flashcards,
  glossary,
  keyPoints,
  revisionPlan,

  // ── Learning navigation ──
  learningPath,
  prerequisiteCheck,
  difficultyUpgrade,
  difficultyReduce,

  // ── Conversational continuity ──
  continueCurrentTask,
  repeatExplanation,
  askFollowup,

  // ── Fallback ──
  generalQuestion,
}

/// Result of intent detection.
class IntentDetectionResult {
  final TutorIntent intent;
  final double confidence;
  final String topic;
  final String? difficulty;
  final String? chapter;
  final String subject;

  const IntentDetectionResult({
    required this.intent,
    required this.confidence,
    required this.topic,
    this.difficulty,
    this.chapter,
    this.subject = 'general',
  });

  /// Whether this intent should be resolved from local assets
  /// rather than routed to RAG + LLM.
  bool get isAssetIntent => const {
    TutorIntent.flashcards,
    TutorIntent.glossary,
    TutorIntent.keyPoints,
    TutorIntent.revisionPlan,
    TutorIntent.startQuiz,
    TutorIntent.continueQuiz,
  }.contains(intent);

  /// Whether this intent should inherit context from SessionState.
  bool get isContextual => const {
    TutorIntent.continueCurrentTask,
    TutorIntent.repeatExplanation,
    TutorIntent.askFollowup,
    TutorIntent.giveHint,
    TutorIntent.difficultyUpgrade,
    TutorIntent.difficultyReduce,
  }.contains(intent);

  @override
  String toString() =>
      'IntentDetectionResult(intent=${intent.name}, confidence=${confidence.toStringAsFixed(2)}, '
      'topic=$topic, difficulty=$difficulty, chapter=$chapter, subject=$subject)';
}

/// Production-grade, fully-offline intent detector.
///
/// Uses a hybrid approach:
///   1. Rule-based pattern matching (highest priority)
///   2. Keyword → intent mapping
///   3. Session context inheritance for follow-ups
///   4. Subject heuristic classification
///
/// No LLM calls are made. Detection runs in < 1 ms.
class IntentDetector {
  IntentDetector();

  // ── Stop words removed before topic extraction ──
  static const _stopWords = <String>{
    'what', 'is', 'the', 'meaning', 'of', 'explain', 'describe', 'tell',
    'me', 'about', 'how', 'does', 'work', 'can', 'you', 'give', 'an',
    'example', 'a', 'to', 'in', 'for', 'on', 'with', 'by', 'as', 'at',
    'show', 'please', 'i', 'want', 'need', 'would', 'like', 'could',
    'do', 'this', 'that', 'some', 'my', 'from', 'are', 'be', 'it',
    'its', 'or', 'and', 'if', 'then', 'so', 'but', 'not', 'no', 'yes',
  };

  // ── Conversational continuity triggers ──
  static const _continuityTriggers = <String, TutorIntent>{
    'another one': TutorIntent.continueCurrentTask,
    'one more': TutorIntent.continueCurrentTask,
    'next one': TutorIntent.continueCurrentTask,
    'more': TutorIntent.continueCurrentTask,
    'continue': TutorIntent.continueCurrentTask,
    'keep going': TutorIntent.continueCurrentTask,
    'again': TutorIntent.repeatExplanation,
    'repeat': TutorIntent.repeatExplanation,
    'say that again': TutorIntent.repeatExplanation,
    'harder': TutorIntent.difficultyUpgrade,
    'more difficult': TutorIntent.difficultyUpgrade,
    'challenge me': TutorIntent.difficultyUpgrade,
    'easier': TutorIntent.difficultyReduce,
    'simpler': TutorIntent.difficultyReduce,
    'too hard': TutorIntent.difficultyReduce,
    'hint': TutorIntent.giveHint,
    'give hint': TutorIntent.giveHint,
    'give me a hint': TutorIntent.giveHint,
    'clue': TutorIntent.giveHint,
  };

  // ── Rule patterns: ordered list, first match wins ──
  static final _rulePatterns = <_IntentRule>[
    // Assessment
    _IntentRule(TutorIntent.startQuiz, RegExp(r'\b(start|begin|take|give me)\b.*\b(quiz|test|exam)\b', caseSensitive: false), 0.95),
    _IntentRule(TutorIntent.continueQuiz, RegExp(r'\b(continue|resume|next question)\b.*\b(quiz|test)\b', caseSensitive: false), 0.95),
    _IntentRule(TutorIntent.revisionTest, RegExp(r'\b(revision|review)\b.*\b(test|quiz|exam)\b', caseSensitive: false), 0.90),
    _IntentRule(TutorIntent.evaluateAnswer, RegExp(r'\b(check|evaluate|grade|mark)\b.*\b(answer|response|solution)\b', caseSensitive: false), 0.90),

    // Structured assets
    _IntentRule(TutorIntent.flashcards, RegExp(r'\b(flashcard|flash card|flashcards|flash cards|card|cards)\b', caseSensitive: false), 0.95),
    _IntentRule(TutorIntent.glossary, RegExp(r'\b(glossary|vocabulary|vocab|terminology|terms)\b', caseSensitive: false), 0.90),
    _IntentRule(TutorIntent.keyPoints, RegExp(r'\b(key\s*points?|important\s*points?|main\s*points?|highlights?|takeaways?)\b', caseSensitive: false), 0.90),
    _IntentRule(TutorIntent.revisionPlan, RegExp(r'\b(revision\s*plan|study\s*plan|revision\s*schedule)\b', caseSensitive: false), 0.90),

    // Problem solving
    _IntentRule(TutorIntent.solveProblem, RegExp(r'\b(solve|calculate|compute|find the value|evaluate|simplify)\b', caseSensitive: false), 0.85),
    _IntentRule(TutorIntent.guidedSolution, RegExp(r'\b(step\s*by\s*step|walk\s*me\s*through|guide|guided)\b', caseSensitive: false), 0.85),
    _IntentRule(TutorIntent.practiceQuestion, RegExp(r'\b(practice|exercise|drill|try|attempt)\b.*\b(question|problem|sum)\b', caseSensitive: false), 0.85),
    _IntentRule(TutorIntent.generateWorksheet, RegExp(r'\b(worksheet|work\s*sheet|problem\s*set|question\s*set)\b', caseSensitive: false), 0.85),

    // Conceptual
    _IntentRule(TutorIntent.compareConcepts, RegExp(r'\b(compare|contrast|difference between|vs|versus|distinguish)\b', caseSensitive: false), 0.85),
    _IntentRule(TutorIntent.defineTerm, RegExp(r'\b(define|definition|what\s+is|what\s+are|what\s+does .+ mean)\b', caseSensitive: false), 0.80),
    _IntentRule(TutorIntent.giveExample, RegExp(r'\b(example|instance|illustrate|show\s*me)\b', caseSensitive: false), 0.80),
    _IntentRule(TutorIntent.summarizeTopic, RegExp(r'\b(summar|recap|overview|brief|outline|wrap\s*up)\b', caseSensitive: false), 0.85),
    _IntentRule(TutorIntent.explainConcept, RegExp(r'\b(explain|describe|elaborate|clarify|teach|tell me about|how does)\b', caseSensitive: false), 0.80),

    // Learning navigation
    _IntentRule(TutorIntent.learningPath, RegExp(r'\b(learning\s*path|what\s+should\s+i\s+learn|roadmap|study\s*order)\b', caseSensitive: false), 0.85),
    _IntentRule(TutorIntent.prerequisiteCheck, RegExp(r'\b(prerequisite|what\s+do\s+i\s+need\s+to\s+know|before\s+learning)\b', caseSensitive: false), 0.85),
  ];

  // ── Subject heuristics ──
  static final _subjectPatterns = <String, RegExp>{
    'math': RegExp(r'\b(math|algebra|geometry|calculate|solve|equation|fraction|polynomial|trigonometry|arithmetic|number|digit)\b', caseSensitive: false),
    'science': RegExp(r'\b(photosynthesis|biology|cell|organism|chemical|experiment|physics|chemistry|atom|molecule|force|energy)\b', caseSensitive: false),
    'social': RegExp(r'\b(history|geography|date|war|empire|civilization|country|continent|revolution|constitution)\b', caseSensitive: false),
    'english': RegExp(r'\b(grammar|sentence|noun|verb|adjective|adverb|tense|pronoun|essay|paragraph|writing|literature)\b', caseSensitive: false),
  };

  /// Detect the user's intent from a question string and optional session state.
  IntentDetectionResult detect(String question, {SessionState? sessionState}) {
    final q = question.trim();
    final qLower = q.toLowerCase();

    // ── Phase 1: Exact continuity triggers ──
    for (final entry in _continuityTriggers.entries) {
      if (qLower == entry.key || qLower == '${entry.key}.' || qLower == '${entry.key}!') {
        final inherited = _inheritFromSession(entry.value, sessionState);
        print('[INTENT] QUESTION=$q');
        print('[INTENT] DETECTED_INTENT=${inherited.intent.name}');
        print('[INTENT] CONFIDENCE=${inherited.confidence.toStringAsFixed(2)}');
        print('[INTENT] TOPIC=${inherited.topic}');
        print('[INTENT] CHAPTER=${inherited.chapter}');
        print('[INTENT] DIFFICULTY=${inherited.difficulty}');
        return inherited;
      }
    }

    // ── Phase 2: Rule-based pattern matching ──
    for (final rule in _rulePatterns) {
      if (rule.pattern.hasMatch(qLower)) {
        final topic = _extractTopic(qLower, rule.pattern);
        final subject = _detectSubject(qLower);
        final result = IntentDetectionResult(
          intent: rule.intent,
          confidence: rule.baseConfidence,
          topic: topic.isNotEmpty ? topic : (sessionState?.activeTopic ?? q),
          difficulty: sessionState?.activeDifficulty,
          chapter: sessionState?.activeChapter,
          subject: subject,
        );
        _logDetection(q, result);
        return result;
      }
    }

    // ── Phase 3: Fallback to generalQuestion ──
    final subject = _detectSubject(qLower);
    final result = IntentDetectionResult(
      intent: TutorIntent.generalQuestion,
      confidence: 0.50,
      topic: _cleanTopic(qLower),
      difficulty: sessionState?.activeDifficulty,
      chapter: sessionState?.activeChapter,
      subject: subject,
    );
    _logDetection(q, result);
    return result;
  }

  /// Inherit context from SessionState for continuity intents.
  IntentDetectionResult _inheritFromSession(TutorIntent continuityIntent, SessionState? state) {
    if (state == null || state.activeIntent == null) {
      return IntentDetectionResult(
        intent: continuityIntent,
        confidence: 0.70,
        topic: state?.activeTopic ?? '',
        difficulty: state?.activeDifficulty,
        chapter: state?.activeChapter,
      );
    }

    // Map continuity intents to the active session intent
    TutorIntent resolvedIntent = continuityIntent;
    if (continuityIntent == TutorIntent.continueCurrentTask) {
      resolvedIntent = state.activeIntent!;
    }

    String? difficulty = state.activeDifficulty;
    if (continuityIntent == TutorIntent.difficultyUpgrade) {
      difficulty = _upgradeDifficulty(difficulty);
    } else if (continuityIntent == TutorIntent.difficultyReduce) {
      difficulty = _reduceDifficulty(difficulty);
    }

    return IntentDetectionResult(
      intent: resolvedIntent,
      confidence: 0.90,
      topic: state.activeTopic ?? '',
      difficulty: difficulty,
      chapter: state.activeChapter,
    );
  }

  /// Extract the educational topic from a query by removing the matched intent pattern and stop words.
  String _extractTopic(String qLower, RegExp intentPattern) {
    String stripped = qLower.replaceAll(intentPattern, ' ');
    return _cleanTopic(stripped);
  }

  /// Clean a raw string into a topic by removing stop words and punctuation.
  String _cleanTopic(String raw) {
    final words = raw
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !_stopWords.contains(w))
        .toList();
    return words.join(' ').trim();
  }

  /// Detect subject from keyword heuristics.
  String _detectSubject(String qLower) {
    for (final entry in _subjectPatterns.entries) {
      if (entry.value.hasMatch(qLower)) return entry.key;
    }
    return 'general';
  }

  String _upgradeDifficulty(String? current) {
    const levels = ['easy', 'medium', 'hard', 'advanced'];
    final idx = levels.indexOf(current ?? 'medium');
    return levels[(idx + 1).clamp(0, levels.length - 1)];
  }

  String _reduceDifficulty(String? current) {
    const levels = ['easy', 'medium', 'hard', 'advanced'];
    final idx = levels.indexOf(current ?? 'medium');
    return levels[(idx - 1).clamp(0, levels.length - 1)];
  }

  void _logDetection(String question, IntentDetectionResult r) {
    print('[INTENT] QUESTION=$question');
    print('[INTENT] DETECTED_INTENT=${r.intent.name}');
    print('[INTENT] CONFIDENCE=${r.confidence.toStringAsFixed(2)}');
    print('[INTENT] TOPIC=${r.topic}');
    print('[INTENT] CHAPTER=${r.chapter}');
    print('[INTENT] DIFFICULTY=${r.difficulty}');
  }
}

/// Internal rule model for pattern-based intent detection.
class _IntentRule {
  final TutorIntent intent;
  final RegExp pattern;
  final double baseConfidence;
  const _IntentRule(this.intent, this.pattern, this.baseConfidence);
}
