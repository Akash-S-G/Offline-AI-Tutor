import 'dart:convert';

import '../../domain/quiz_result.dart';
import '../../../course/data/local/app_database.dart';

class QuizResultRepository {
  Future<int> saveResult(QuizResult result) async {
    final db = await AppDatabase.instance.database;
    return await db.insert(
      'quiz_results',
      {
        'chapter_id': result.chapterId,
        'score': result.score,
        'total_questions': result.totalQuestions,
        'answers_json': jsonEncode(result.answers),
        'attempted_at': result.attemptedAt.millisecondsSinceEpoch,
      },
    );
  }

  Future<List<QuizResult>> getChapterResults(String chapterId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'quiz_results',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'attempted_at DESC',
    );

    return rows
        .map((row) => QuizResult(
              id: row['id'] as int?,
              chapterId: row['chapter_id'] as String,
              score: (row['score'] as int),
              totalQuestions: (row['total_questions'] as int),
              answers: Map<int, int>.from(
                jsonDecode(row['answers_json'] as String) as Map,
              ),
              attemptedAt: DateTime.fromMillisecondsSinceEpoch(
                row['attempted_at'] as int,
              ),
            ))
        .toList();
  }

  Future<List<QuizResult>> getAllResults() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'quiz_results',
      orderBy: 'attempted_at DESC',
    );

    return rows
        .map((row) => QuizResult(
              id: row['id'] as int?,
              chapterId: row['chapter_id'] as String,
              score: (row['score'] as int),
              totalQuestions: (row['total_questions'] as int),
              answers: Map<int, int>.from(
                jsonDecode(row['answers_json'] as String) as Map,
              ),
              attemptedAt: DateTime.fromMillisecondsSinceEpoch(
                row['attempted_at'] as int,
              ),
            ))
        .toList();
  }

  Future<QuizResult?> getLatestChapterResult(String chapterId) async {
    final results = await getChapterResults(chapterId);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> deleteResult(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'quiz_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getAverageScoresByChapter() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT chapter_id, AVG(CAST(score AS REAL) / total_questions * 100) as avg_score
      FROM quiz_results
      GROUP BY chapter_id
    ''');

    final result = <String, double>{};
    for (final row in rows) {
      result[row['chapter_id'] as String] = (row['avg_score'] as num).toDouble();
    }
    return result;
  }
}
