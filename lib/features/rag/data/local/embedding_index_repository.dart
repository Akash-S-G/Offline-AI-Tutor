import 'package:sqflite/sqflite.dart';

import '../../../course/data/local/app_database.dart';

class EmbeddingIndexRepository {
  EmbeddingIndexRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> upsertEmbeddingMetadata({
    required String chunkId,
    required String modelName,
    required int dimension,
  }) async {
    final db = await _database.database;
    await db.insert(
      'rag_chunk_embeddings',
      {
        'chunk_id': chunkId,
        'model_name': modelName,
        'dimension': dimension,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getIndexedCount() async {
    final db = await _database.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM rag_chunk_embeddings');
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<int> getIndexedCountForChapter({required String chapterId}) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS c
      FROM rag_chunk_embeddings emb
      INNER JOIN rag_chunks rc ON rc.id = emb.chunk_id
      WHERE rc.chapter_id = ?
      ''',
      [chapterId],
    );

    return (rows.first['c'] as int?) ?? 0;
  }

  Future<bool> isChunkIndexed({required String chunkId}) async {
    final db = await _database.database;
    final rows = await db.query(
      'rag_chunk_embeddings',
      columns: ['chunk_id'],
      where: 'chunk_id = ?',
      whereArgs: [chunkId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
