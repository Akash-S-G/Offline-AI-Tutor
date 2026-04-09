import '../../../course/data/local/app_database.dart';

class ChatBenchmarkRun {
  const ChatBenchmarkRun({
    required this.id,
    required this.chapterId,
    required this.mode,
    required this.promptCount,
    required this.avgTtftMs,
    required this.avgTotalMs,
    required this.avgTokensPerSec,
    required this.createdAt,
    required this.notes,
  });

  final int id;
  final String chapterId;
  final String mode;
  final int promptCount;
  final int avgTtftMs;
  final int avgTotalMs;
  final double avgTokensPerSec;
  final DateTime createdAt;
  final String notes;
}

class ChatBenchmarkItem {
  const ChatBenchmarkItem({
    required this.promptText,
    required this.ttftMs,
    required this.totalMs,
    required this.tokens,
    required this.tokensPerSec,
  });

  final String promptText;
  final int ttftMs;
  final int totalMs;
  final int tokens;
  final double tokensPerSec;
}

class ChatBenchmarkRepository {
  ChatBenchmarkRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<int> saveRun({
    required String chapterId,
    required String mode,
    required List<ChatBenchmarkItem> items,
    String notes = '',
  }) async {
    final db = await _database.database;
    if (items.isEmpty) {
      throw Exception('Cannot save empty benchmark run.');
    }

    final avgTtftMs =
        items.map((e) => e.ttftMs).reduce((a, b) => a + b) ~/ items.length;
    final avgTotalMs =
        items.map((e) => e.totalMs).reduce((a, b) => a + b) ~/ items.length;
    final avgTokensPerSec =
        items.map((e) => e.tokensPerSec).reduce((a, b) => a + b) / items.length;

    return db.transaction<int>((txn) async {
      final runId = await txn.insert(
        'chat_benchmark_runs',
        <String, Object?>{
          'chapter_id': chapterId,
          'mode': mode,
          'prompt_count': items.length,
          'avg_ttft_ms': avgTtftMs,
          'avg_total_ms': avgTotalMs,
          'avg_tokens_per_sec': avgTokensPerSec,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'notes': notes,
        },
      );

      final batch = txn.batch();
      for (final item in items) {
        batch.insert(
          'chat_benchmark_items',
          <String, Object?>{
            'run_id': runId,
            'prompt_text': item.promptText,
            'ttft_ms': item.ttftMs,
            'total_ms': item.totalMs,
            'tokens': item.tokens,
            'tokens_per_sec': item.tokensPerSec,
          },
        );
      }
      await batch.commit(noResult: true);
      return runId;
    });
  }

  Future<ChatBenchmarkRun?> getLatestRun({
    required String chapterId,
    required String mode,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'chat_benchmark_runs',
      where: 'chapter_id = ? AND mode = ?',
      whereArgs: <Object?>[chapterId, mode],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return ChatBenchmarkRun(
      id: row['id'] as int,
      chapterId: row['chapter_id'] as String,
      mode: row['mode'] as String,
      promptCount: row['prompt_count'] as int,
      avgTtftMs: row['avg_ttft_ms'] as int,
      avgTotalMs: row['avg_total_ms'] as int,
      avgTokensPerSec: (row['avg_tokens_per_sec'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      notes: (row['notes'] as String?) ?? '',
    );
  }

  Future<List<ChatBenchmarkItem>> getItemsForRun(int runId) async {
    final db = await _database.database;
    final rows = await db.query(
      'chat_benchmark_items',
      where: 'run_id = ?',
      whereArgs: <Object?>[runId],
      orderBy: 'id ASC',
    );

    return rows
        .map(
          (row) => ChatBenchmarkItem(
            promptText: row['prompt_text'] as String,
            ttftMs: row['ttft_ms'] as int,
            totalMs: row['total_ms'] as int,
            tokens: row['tokens'] as int,
            tokensPerSec: (row['tokens_per_sec'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<List<ChatBenchmarkRun>> getRecentRuns({
    required String chapterId,
    required String mode,
    int limit = 5,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'chat_benchmark_runs',
      where: 'chapter_id = ? AND mode = ?',
      whereArgs: <Object?>[chapterId, mode],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return rows
        .map(
          (row) => ChatBenchmarkRun(
            id: row['id'] as int,
            chapterId: row['chapter_id'] as String,
            mode: row['mode'] as String,
            promptCount: row['prompt_count'] as int,
            avgTtftMs: row['avg_ttft_ms'] as int,
            avgTotalMs: row['avg_total_ms'] as int,
            avgTokensPerSec: (row['avg_tokens_per_sec'] as num).toDouble(),
            createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
            notes: (row['notes'] as String?) ?? '',
          ),
        )
        .toList();
  }
}
