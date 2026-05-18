import 'package:uuid/uuid.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';
import '../../../config/app_environment.dart';
import 'dart:math' as math;

/// Quiz session tracking
class QuizSession {
  final String id;
  final String quizId;
  final int chapterId;
  final int userId; // Learner ID (for multi-user)
  final List<QuestionAttempt> attempts;
  final DateTime startedAt;
  DateTime? completedAt;
  
  QuizSession({
    required this.id,
    required this.quizId,
    required this.chapterId,
    required this.userId,
    required this.startedAt,
    this.attempts = const [],
    this.completedAt,
  });

  bool get isCompleted => completedAt != null;
  int get correctCount => attempts.where((a) => a.isCorrect).length;
  double get scorePercentage => attempts.isEmpty ? 0 : (correctCount / attempts.length) * 100;
  Duration get duration => Duration(
    milliseconds: (completedAt ?? DateTime.now()).difference(startedAt).inMilliseconds,
  );
}

/// Single question attempt in a session
class QuestionAttempt {
  final String questionId;
  final String userAnswer;
  final String correctAnswer;
  final int pointsEarned;
  final Duration timeSpent;
  final DateTime attemptedAt;

  QuestionAttempt({
    required this.questionId,
    required this.userAnswer,
    required this.correctAnswer,
    required this.pointsEarned,
    required this.timeSpent,
    required this.attemptedAt,
  });

  bool get isCorrect => userAnswer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
}

/// Quiz engine for executing and scoring quizzes
class QuizEngine {
  static final QuizEngine _instance = QuizEngine._internal();

  factory QuizEngine() {
    return _instance;
  }

  QuizEngine._internal();

  final Map<String, QuizSession> _activeSessions = {};
  final _uuid = const Uuid();

  /// Start a new quiz session
  Future<QuizSession?> startQuiz(
    String quizId, {
    required int chapterId,
    int userId = 1,
  }) async {
    try {
      AppEnvironment.log('SYNC', '[QuizEngine] Starting quiz: $quizId');

      final quizzes = await EducationalRepository.getQuizzesByChapterId(chapterId);
      QuizModel? quiz;
      try {
        quiz = quizzes.firstWhere((q) => q.id.toString() == quizId);
      } catch (e) {
        quiz = null;
      }

      if (quiz == null) {
        AppEnvironment.log('SYNC', '[QuizEngine] Quiz not found: $quizId');
        return null;
      }

      final sessionId = _uuid.v4();
      final session = QuizSession(
        id: sessionId,
        quizId: quizId,
        chapterId: chapterId,
        userId: userId,
        startedAt: DateTime.now(),
      );

      _activeSessions[sessionId] = session;
      return session;
    } catch (e) {
      AppEnvironment.log('SYNC', '[QuizEngine] Error starting quiz: $e');
      return null;
    }
  }

  /// Submit answer to a question
  Future<QuestionAttempt?> submitAnswer(
    String sessionId,
    String questionId,
    String userAnswer,
    Duration timeSpent,
  ) async {
    try {
      final session = _activeSessions[sessionId];
      if (session == null) {
        AppEnvironment.log('SYNC', '[QuizEngine] Session not found: $sessionId');
        return null;
      }

      // Get the quiz to find the question
      final quizzes = await EducationalRepository.getQuizzesByChapterId(session.chapterId);
      QuizModel? quiz;
      try {
        quiz = quizzes.firstWhere((q) => q.id.toString() == session.quizId);
      } catch (e) {
        quiz = null;
      }

      if (quiz == null) return null;

      if (quiz.id == null) return null;

      final questions = await EducationalRepository.getQuizQuestions(quiz.id!);
      QuizQuestion? question;
      try {
        question = questions.firstWhere(
          (q) => q.id.toString() == questionId,
        );
      } catch (e) {
        question = null;
      }

      if (question == null) return null;

      // Score the answer
      final isCorrect = userAnswer.toLowerCase().trim() == question.correctAnswer.toLowerCase().trim();
      final pointsEarned = isCorrect ? question.points : 0;

      final attempt = QuestionAttempt(
        questionId: questionId,
        userAnswer: userAnswer,
        correctAnswer: question.correctAnswer,
        pointsEarned: pointsEarned,
        timeSpent: timeSpent,
        attemptedAt: DateTime.now(),
      );

      // Update session (create new list to maintain immutability)
      final updatedSession = QuizSession(
        id: session.id,
        quizId: session.quizId,
        chapterId: session.chapterId,
        userId: session.userId,
        startedAt: session.startedAt,
        attempts: [...session.attempts, attempt],
        completedAt: session.completedAt,
      );
      _activeSessions[sessionId] = updatedSession;

      AppEnvironment.log(
        'SYNC',
        '[QuizEngine] Question answered (${isCorrect ? 'correct' : 'incorrect'}): $questionId',
      );

      return attempt;
    } catch (e) {
      AppEnvironment.log('SYNC', '[QuizEngine] Error submitting answer: $e');
      return null;
    }
  }

  /// Complete and save quiz session
  Future<QuizSession?> completeQuiz(String sessionId) async {
    try {
      var session = _activeSessions[sessionId];
      if (session == null) return null;

      session = QuizSession(
        id: session.id,
        quizId: session.quizId,
        chapterId: session.chapterId,
        userId: session.userId,
        startedAt: session.startedAt,
        attempts: session.attempts,
        completedAt: DateTime.now(),
      );

      _activeSessions[sessionId] = session;

      // TODO: Save session to database
      // await EducationalRepository.saveQuizSession(session);

      AppEnvironment.log(
        'SYNC',
        '[QuizEngine] Quiz completed (score: ${session.scorePercentage.toStringAsFixed(1)}%)',
      );

      return session;
    } catch (e) {
      AppEnvironment.log('SYNC', '[QuizEngine] Error completing quiz: $e');
      return null;
    }
  }

  /// Get active session
  QuizSession? getSession(String sessionId) => _activeSessions[sessionId];

  /// Abandon quiz session
  void abandonQuiz(String sessionId) {
    _activeSessions.remove(sessionId);
    AppEnvironment.log('SYNC', '[QuizEngine] Quiz abandoned: $sessionId');
  }

  /// Check if passed quiz (>= passing score)
  bool checkPassed(QuizSession session, int passingScorePercent) {
    return session.scorePercentage >= passingScorePercent;
  }
}

/// Flashcard with spaced repetition scheduling
class FlashcardReview {
  final String id;
  final FlashcardModel flashcard;
  int reviewCount;
  int correctCount;
  DateTime lastReviewedAt;
  DateTime? nextReviewAt;
  int easinessFactor; // For SM-2 algorithm (10-250)
  int interval; // Days until next review

  FlashcardReview({
    required this.id,
    required this.flashcard,
    this.reviewCount = 0,
    this.correctCount = 0,
    required this.lastReviewedAt,
    this.nextReviewAt,
    this.easinessFactor = 250, // Start at 2.5
    this.interval = 1,
  });

  bool get isDue {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  double get retentionRate => reviewCount == 0 ? 0 : (correctCount / reviewCount) * 100;
}

/// Flashcard engine with spaced repetition (SM-2 algorithm)
class FlashcardEngine {
  static final FlashcardEngine _instance = FlashcardEngine._internal();

  factory FlashcardEngine() {
    return _instance;
  }

  FlashcardEngine._internal();

  final Map<String, FlashcardReview> _reviews = {};

  /// Initialize flashcard reviews for a chapter
  Future<List<FlashcardReview>> initializeChapterFlashcards(int chapterId) async {
    try {
      final flashcards = await EducationalRepository.getFlashcardsByChapterId(chapterId);
      
      final reviews = flashcards.map((fc) {
        return FlashcardReview(
          id: _generateId(),
          flashcard: fc,
          lastReviewedAt: DateTime.now(),
          nextReviewAt: DateTime.now(),
        );
      }).toList();

      for (final review in reviews) {
        _reviews[review.id] = review;
      }

      AppEnvironment.log('SYNC', '[FlashcardEngine] Initialized ${reviews.length} flashcards for chapter $chapterId');
      return reviews;
    } catch (e) {
      AppEnvironment.log('SYNC', '[FlashcardEngine] Error initializing flashcards: $e');
      return [];
    }
  }

  /// Get flashcards due for review
  List<FlashcardReview> getReviewsDue({int limit = 20}) {
    final due = _reviews.values.where((r) => r.isDue).toList();
    due.sort((a, b) => a.nextReviewAt?.compareTo(b.nextReviewAt ?? DateTime.now()) ?? -1);
    return due.take(limit).toList();
  }

  /// Record flashcard review using SM-2 algorithm
  /// quality: 0-5 rating of answer quality
  void recordReview(String reviewId, int quality) {
    final review = _reviews[reviewId];
    if (review == null) return;

    // SM-2 algorithm
    const minEF = 1300; // 1.3
    const maxEF = 2600; // 2.6

    // Update review counts
    review.reviewCount++;
    if (quality >= 3) {
      review.correctCount++;
    }

    // Calculate new easiness factor
    final newEF = review.easinessFactor +
        (250 * (quality - 3) * (1 - 2 + 2 * ((5 - quality) / 5).toInt()));
    review.easinessFactor = newEF.clamp(minEF, maxEF).toInt();

    // Calculate new interval
    if (review.reviewCount == 1) {
      review.interval = 1;
    } else if (review.reviewCount == 2) {
      review.interval = 3;
    } else {
      review.interval = (review.interval * (review.easinessFactor / 1000)).ceil();
    }

    // Schedule next review
    review.lastReviewedAt = DateTime.now();
    review.nextReviewAt = DateTime.now().add(Duration(days: review.interval));

    AppEnvironment.log(
      'SYNC',
      '[FlashcardEngine] Reviewed: quality=$quality, EF=${(review.easinessFactor / 100).toStringAsFixed(2)}, interval=${review.interval}d',
    );
  }

  /// Get review statistics
  Map<String, dynamic> getStatistics() {
    final totalReviews = _reviews.length;
    final reviewedToday = _reviews.values
        .where((r) =>
            r.lastReviewedAt.day == DateTime.now().day &&
            r.lastReviewedAt.month == DateTime.now().month &&
            r.lastReviewedAt.year == DateTime.now().year)
        .length;
    final dueCount = _reviews.values.where((r) => r.isDue).length;
    final avgRetention = _reviews.isEmpty
        ? 0.0
        : _reviews.values.fold(0.0, (sum, r) => sum + r.retentionRate) / _reviews.length;

    return {
      'totalFlashcards': totalReviews,
      'reviewedToday': reviewedToday,
      'dueForReview': dueCount,
      'averageRetention': avgRetention,
    };
  }

  String _generateId() => '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
}

/// Progress tracker for learner activity
class ProgressTracker {
  static final ProgressTracker _instance = ProgressTracker._internal();

  factory ProgressTracker() {
    return _instance;
  }

  ProgressTracker._internal();

  /// Update chapter progress
  Future<void> updateChapterProgress(
    int chapterId, {
    required String completionState,
    required int readingProgressPercent,
    required int quizAttempts,
    required int quizBestScore,
    required int flashcardsReviewed,
  }) async {
    try {
      final existing = await EducationalRepository.getProgressByChapterId(chapterId);
      
      final progress = LearnerProgressModel(
        id: existing?.id,
        chapterId: chapterId,
        completionState: completionState,
        readingProgressPercent: readingProgressPercent,
        quizAttempts: quizAttempts,
        quizBestScore: quizBestScore,
        flashcardsReviewed: flashcardsReviewed,
        lastAccessedAt: DateTime.now(),
        completedAt: completionState == 'completed' ? DateTime.now() : existing?.completedAt,
        createdAt: existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existing == null) {
        await EducationalRepository.insertProgress(progress);
      } else {
        await EducationalRepository.updateProgress(progress);
      }

      AppEnvironment.log('SYNC', '[ProgressTracker] Updated chapter $chapterId: $completionState');
    } catch (e) {
      AppEnvironment.log('SYNC', '[ProgressTracker] Error updating progress: $e');
    }
  }

  /// Get learning statistics
  Future<Map<String, dynamic>> getLearnerStatistics(List<int> chapterIds) async {
    try {
      var totalReadMinutes = 0;
      var chaptersCompleted = 0;
      var totalQuizScore = 0;
      var quizzes = 0;
      var flashcardsReviewed = 0;

      for (final chapterId in chapterIds) {
        final progress = await EducationalRepository.getProgressByChapterId(chapterId);
        if (progress != null) {
          totalReadMinutes += (progress.readingProgressPercent / 100 * 30).ceil(); // Assume 30min per chapter
          if (progress.completionState == 'completed') {
            chaptersCompleted++;
          }
          if ((progress.quizAttempts ?? 0) > 0) {
            totalQuizScore += (progress.quizBestScore ?? 0);
            quizzes++;
          }
          flashcardsReviewed += (progress.flashcardsReviewed ?? 0);
        }
      }

      return {
        'totalChapters': chapterIds.length,
        'chaptersCompleted': chaptersCompleted,
        'completionPercent': chapterIds.isEmpty ? 0 : (chaptersCompleted / chapterIds.length * 100).toStringAsFixed(1),
        'totalReadMinutes': totalReadMinutes,
        'quizzesAttempted': quizzes,
        'averageQuizScore': quizzes == 0 ? 0 : (totalQuizScore / quizzes).toStringAsFixed(1),
        'flashcardsReviewed': flashcardsReviewed,
      };
    } catch (e) {
      AppEnvironment.log('SYNC', '[ProgressTracker] Error getting statistics: $e');
      return {};
    }
  }
}
