import 'package:sqflite/sqflite.dart';

import '../../../course/data/local/app_database.dart';
import '../../domain/chunk_v2.dart';

/// Repository for enhanced chunks (v2) with semantic typing and formulas
class RagRepositoryV2 {
  RagRepositoryV2({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  /// Insert new chunk
  Future<void> insertChunk(ChunkV2 chunk) async {
    final db = await _database.database;
    await db.insert(
      'rag_chunks_v2',
      {
        'id': chunk.id,
        'chapter_id': chunk.chapterId,
        'source_language': chunk.sourceLanguage,
        'source_title': chunk.sourceTitle,
        'chunk_order': chunk.chunkOrder,
        'content_type': chunk.contentType,
        'content': chunk.content,
        'formulas_json': chunk.formulasJson,
        'original_markdown': chunk.originalMarkdown,
        'token_count': chunk.tokenCount,
        'metadata_json': chunk.metadataJson,
        'created_at': chunk.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple chunks (batch)
  Future<void> insertChunks(List<ChunkV2> chunks) async {
    if (chunks.isEmpty) return;
    final db = await _database.database;
    final batch = db.batch();

    for (final chunk in chunks) {
      batch.insert(
        'rag_chunks_v2',
        {
          'id': chunk.id,
          'chapter_id': chunk.chapterId,
          'source_language': chunk.sourceLanguage,
          'source_title': chunk.sourceTitle,
          'chunk_order': chunk.chunkOrder,
          'content_type': chunk.contentType,
          'content': chunk.content,
          'formulas_json': chunk.formulasJson,
          'original_markdown': chunk.originalMarkdown,
          'token_count': chunk.tokenCount,
          'metadata_json': chunk.metadataJson,
          'created_at': chunk.createdAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get chunks for chapter
  Future<List<ChunkV2>> getChunksForChapter(
    String chapterId, {
    String? language,
  }) async {
    final db = await _database.database;

    final query = await db.query(
      'rag_chunks_v2',
      where: language == null
          ? 'chapter_id = ?'
          : 'chapter_id = ? AND source_language = ?',
      whereArgs:
          language == null ? [chapterId] : [chapterId, language],
      orderBy: 'chunk_order ASC',
    );

    return query.map((row) => ChunkV2.fromJson(row)).toList();
  }

  /// Get chunks by content type (definitions, examples, etc.)
  Future<List<ChunkV2>> getChunksByType(
    String chapterId,
    String contentType, {
    String? language,
  }) async {
    final db = await _database.database;

    final query = await db.query(
      'rag_chunks_v2',
      where: language == null
          ? 'chapter_id = ? AND content_type = ?'
          : 'chapter_id = ? AND content_type = ? AND source_language = ?',
      whereArgs: language == null
          ? [chapterId, contentType]
          : [chapterId, contentType, language],
      orderBy: 'chunk_order ASC',
    );

    return query.map((row) => ChunkV2.fromJson(row)).toList();
  }

  /// Search using full-text search (v2 FTS)
  Future<List<ChunkV2>> searchChunks(
    String query,
    String chapterId, {
    int limit = 15,
    String? language,
  }) async {
    final db = await _database.database;
    final normalizedQuery = _buildFtsQuery(query);

    if (normalizedQuery.isEmpty) {
      return getChunksForChapter(chapterId, language: language);
    }

    try {
      final rows = await db.rawQuery(
        '''
        SELECT rc.* FROM rag_chunks_v2 rc
        INNER JOIN rag_chunks_v2_fts fts ON fts.id = rc.id
        WHERE rc.chapter_id = ?
          ${language != null ? ' AND rc.source_language = ? ' : ''}
          AND rag_chunks_v2_fts MATCH ?
        ORDER BY rc.chunk_order ASC
        LIMIT ?
        ''',
        language == null
            ? [chapterId, normalizedQuery, limit]
            : [chapterId, language, normalizedQuery, limit],
      );

      return rows.map((row) => ChunkV2.fromJson(row)).toList();
    } catch (_) {
      // Fallback to simple search if FTS fails
      return getChunksForChapter(chapterId, language: language);
    }
  }

  /// Get count of chunks for chapter
  Future<int> getChunkCount(String chapterId, {String? language}) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      language == null
          ? 'SELECT COUNT(*) AS c FROM rag_chunks_v2 WHERE chapter_id = ?'
          : 'SELECT COUNT(*) AS c FROM rag_chunks_v2 WHERE chapter_id = ? AND source_language = ?',
      language == null ? [chapterId] : [chapterId, language],
    );

    return (rows.first['c'] as int?) ?? 0;
  }

  /// Get chunks with formulas
  Future<List<ChunkV2>> getChunksWithFormulas(
    String chapterId, {
    String? language,
  }) async {
    final db = await _database.database;

    final query = await db.query(
      'rag_chunks_v2',
      where: language == null
          ? 'chapter_id = ? AND formulas_json IS NOT NULL AND formulas_json != ?'
          : 'chapter_id = ? AND source_language = ? AND formulas_json IS NOT NULL AND formulas_json != ?',
      whereArgs: language == null
          ? [chapterId, '[]']
          : [chapterId, language, '[]'],
      orderBy: 'token_count DESC',
    );

    return query.map((row) => ChunkV2.fromJson(row)).toList();
  }

  /// Delete chunks for chapter (for re-ingestion)
  Future<void> deleteChunksForChapter(String chapterId) async {
    final db = await _database.database;
    await db.delete(
      'rag_chunks_v2',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
  }

  /// Get chunk by ID
  Future<ChunkV2?> getChunkById(String chunkId) async {
    final db = await _database.database;
    final rows = await db.query(
      'rag_chunks_v2',
      where: 'id = ?',
      whereArgs: [chunkId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return ChunkV2.fromJson(rows.first);
  }

  /// Get total count of all chunks across all chapters
  Future<int> getTotalChunkCount() async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM rag_chunks_v2',
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Build FTS query from user input
  static String _buildFtsQuery(String query) {
    if (query.trim().isEmpty) return '';

    // Split into words and add fuzzy search operator
    final words = query.split(RegExp(r'\s+'));
    final ftsTerms = words.map((w) => '$w*').join(' ');

    return ftsTerms;
  }
}
