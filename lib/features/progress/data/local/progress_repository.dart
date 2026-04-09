import '../../../course/data/local/app_database.dart';
import '../../../course/domain/course_tree.dart';

class ChapterProgress {
  ChapterProgress({
    required this.chapterId,
    required this.questionsAsked,
    required this.sessionsEngaged,
    required this.totalMessages,
    required this.masteryScore,
    required this.lastActivityAt,
  });

  final String chapterId;
  final int questionsAsked;
  final int sessionsEngaged;
  final int totalMessages;
  final double masteryScore;
  final int lastActivityAt;

  String get masteryLevel {
    if (masteryScore >= 80.0) return 'Advanced';
    if (masteryScore >= 50.0) return 'Intermediate';
    return 'Beginner';
  }
}

class ChapterWithProgress {
  ChapterWithProgress({
    required this.chapter,
    required this.progress,
  });

  final Chapter chapter;
  final ChapterProgress progress;
}

class ProgressRepository {
  ProgressRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> recordQuestionAsked({required String chapterId}) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final rows = await db.query(
      'learner_progress',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );

    if (rows.isEmpty) {
      await db.insert('learner_progress', {
        'chapter_id': chapterId,
        'questions_asked': 1,
        'sessions_engaged': 1,
        'total_messages': 0,
        'mastery_score': _calculateMasteryScore(
          questionsAsked: 1,
          sessionsEngaged: 1,
          totalMessages: 0,
        ),
        'last_activity_at': now,
      });
      return;
    }

    final current = rows.first['questions_asked'] as int;
    final sessions = rows.first['sessions_engaged'] as int;
    final messages = rows.first['total_messages'] as int;

    await db.update(
      'learner_progress',
      {
        'questions_asked': current + 1,
        'mastery_score': _calculateMasteryScore(
          questionsAsked: current + 1,
          sessionsEngaged: sessions,
          totalMessages: messages,
        ),
        'last_activity_at': now,
      },
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
  }

  Future<void> recordChatMessage({
    required String chapterId,
    required String sessionId,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final rows = await db.query(
      'learner_progress',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      final messages = rows.first['total_messages'] as int;
      final sessions = rows.first['sessions_engaged'] as int;
      final questions = rows.first['questions_asked'] as int;

      await db.update(
        'learner_progress',
        {
          'total_messages': messages + 1,
          'mastery_score': _calculateMasteryScore(
            questionsAsked: questions,
            sessionsEngaged: sessions,
            totalMessages: messages + 1,
          ),
          'last_activity_at': now,
        },
        where: 'chapter_id = ?',
        whereArgs: [chapterId],
      );
    }
  }

  Future<void> recordNewSession({required String chapterId}) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final rows = await db.query(
      'learner_progress',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      final sessions = rows.first['sessions_engaged'] as int;
      final questions = rows.first['questions_asked'] as int;
      final messages = rows.first['total_messages'] as int;

      await db.update(
        'learner_progress',
        {
          'sessions_engaged': sessions + 1,
          'mastery_score': _calculateMasteryScore(
            questionsAsked: questions,
            sessionsEngaged: sessions + 1,
            totalMessages: messages,
          ),
          'last_activity_at': now,
        },
        where: 'chapter_id = ?',
        whereArgs: [chapterId],
      );
    }
  }

  Future<int> getQuestionCount({required String chapterId}) async {
    final db = await _database.database;
    final rows = await db.query(
      'learner_progress',
      columns: ['questions_asked'],
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return 0;
    }

    return rows.first['questions_asked'] as int;
  }

  Future<ChapterProgress?> getChapterProgress({
    required String chapterId,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'learner_progress',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return ChapterProgress(
      chapterId: row['chapter_id'] as String,
      questionsAsked: row['questions_asked'] as int,
      sessionsEngaged: row['sessions_engaged'] as int? ?? 1,
      totalMessages: row['total_messages'] as int? ?? 0,
      masteryScore: (row['mastery_score'] as num?)?.toDouble() ?? 0.0,
      lastActivityAt: row['last_activity_at'] as int,
    );
  }

  Future<List<ChapterProgress>> getAllChapterProgress() async {
    final db = await _database.database;
    final rows = await db.query(
      'learner_progress',
      orderBy: 'last_activity_at DESC',
    );

    return [
      for (final row in rows)
        ChapterProgress(
          chapterId: row['chapter_id'] as String,
          questionsAsked: row['questions_asked'] as int,
          sessionsEngaged: row['sessions_engaged'] as int? ?? 1,
          totalMessages: row['total_messages'] as int? ?? 0,
          masteryScore: (row['mastery_score'] as num?)?.toDouble() ?? 0.0,
          lastActivityAt: row['last_activity_at'] as int,
        )
    ];
  }

  double _calculateMasteryScore({
    required int questionsAsked,
    required int sessionsEngaged,
    required int totalMessages,
  }) {
    // Mastery = 30% (questions) + 30% (sessions) + 40% (engagement via messages)
    // Each metric scaled to 0-100
    final questionScore = (questionsAsked * 10).clamp(0, 100).toDouble();
    final sessionScore = (sessionsEngaged * 15).clamp(0, 100).toDouble();
    final messageScore = (totalMessages * 0.5).clamp(0, 100).toDouble();

    final mastery = (questionScore * 0.3) + (sessionScore * 0.3) + (messageScore * 0.4);
    return mastery.clamp(0, 100);
  }
}
