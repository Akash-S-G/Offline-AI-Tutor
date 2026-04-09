import 'package:sqflite/sqflite.dart';

import '../../../course/data/local/app_database.dart';
import '../../domain/rag_chunk.dart';

class RagRepository {
  RagRepository({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> ensureSeedChunks() async {
    final db = await _database.database;
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM rag_chunks'),
    );

    if ((existing ?? 0) > 0) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();

    batch.insert('rag_chunks', {
      'id': 'chunk_linear_1',
      'chapter_id': 'chap_linear_eq',
      'source_title': 'Linear Equations Notes',
      'chunk_order': 1,
      'content': 'A linear equation in one variable has the form ax + b = 0 where a is not zero. Solve by isolating x using inverse operations on both sides.',
      'created_at': now,
    });

    batch.insert('rag_chunks', {
      'id': 'chunk_linear_2',
      'chapter_id': 'chap_linear_eq',
      'source_title': 'Linear Equations Notes',
      'chunk_order': 2,
      'content': 'For word problems, define the unknown as x, write an equation from the statement, simplify, solve, and verify the solution in context.',
      'created_at': now,
    });

    batch.insert('rag_chunks', {
      'id': 'chunk_rxn_1',
      'chapter_id': 'chap_chemical_rxn',
      'source_title': 'Chemical Reactions Notes',
      'chunk_order': 1,
      'content': 'A chemical reaction changes reactants into products. Common signs are color change, gas release, precipitate formation, and temperature change.',
      'created_at': now,
    });

    batch.insert('rag_chunks', {
      'id': 'chunk_rxn_2',
      'chapter_id': 'chap_chemical_rxn',
      'source_title': 'Chemical Reactions Notes',
      'chunk_order': 2,
      'content': 'Balanced equations follow conservation of mass. Adjust coefficients, not subscripts, until atom counts are equal on both sides.',
      'created_at': now,
    });

    await batch.commit(noResult: true);
  }

  Future<void> ingestChapterNotes({
    required String chapterId,
    required String sourceTitle,
    required String rawText,
  }) async {
    final db = await _database.database;
    final normalized = rawText.trim();
    if (normalized.isEmpty) {
      return;
    }

    final chunks = _chunkText(normalized);
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < chunks.length; i++) {
      batch.insert('rag_chunks', {
        'id': '${chapterId}_${now}_$i',
        'chapter_id': chapterId,
        'source_title': sourceTitle,
        'chunk_order': i,
        'content': chunks[i],
        'created_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  Future<List<RagChunk>> getChunksForChapter(String chapterId) async {
    final db = await _database.database;
    final rows = await db.query(
      'rag_chunks',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'chunk_order ASC, created_at DESC',
    );

    return rows
        .map(
          (row) => RagChunk(
            id: row['id'] as String,
            chapterId: row['chapter_id'] as String,
            sourceTitle: row['source_title'] as String,
            chunkOrder: row['chunk_order'] as int,
            content: row['content'] as String,
          ),
        )
        .toList();
  }

  Future<List<String>> getChunkIdsForChapter(String chapterId) async {
    final db = await _database.database;
    final rows = await db.query(
      'rag_chunks',
      columns: ['id'],
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'chunk_order ASC, created_at DESC',
    );

    return rows.map((row) => row['id'] as String).toList();
  }

  Future<int> getChunkCountForChapter(String chapterId) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM rag_chunks WHERE chapter_id = ?',
      [chapterId],
    );

    return (rows.first['c'] as int?) ?? 0;
  }

  Future<List<RagChunk>> searchChunksForChapter({
    required String chapterId,
    required String query,
    int limit = 10,
  }) async {
    final db = await _database.database;
    final normalizedQuery = _buildFtsQuery(query);

    if (normalizedQuery.isEmpty) {
      return getChunksForChapter(chapterId);
    }

    try {
      final rows = await db.rawQuery(
        '''
        SELECT rc.id, rc.chapter_id, rc.source_title, rc.chunk_order, rc.content
        FROM rag_chunks rc
        INNER JOIN rag_chunks_fts fts ON fts.id = rc.id
        WHERE fts.chapter_id = ?
          AND rag_chunks_fts MATCH ?
        ORDER BY rc.created_at DESC, rc.chunk_order ASC
        LIMIT ?
        ''',
        [chapterId, normalizedQuery, limit],
      );

      return rows
          .map(
            (row) => RagChunk(
              id: row['id'] as String,
              chapterId: row['chapter_id'] as String,
              sourceTitle: row['source_title'] as String,
              chunkOrder: row['chunk_order'] as int,
              content: row['content'] as String,
            ),
          )
          .toList();
    } catch (_) {
      return getChunksForChapter(chapterId);
    }
  }

  List<String> _chunkText(String text) {
    final paragraphChunks = text
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (paragraphChunks.isEmpty) {
      return const [];
    }

    const maxChars = 420;
    final output = <String>[];

    for (final paragraph in paragraphChunks) {
      if (paragraph.length <= maxChars) {
        output.add(paragraph);
        continue;
      }

      var start = 0;
      while (start < paragraph.length) {
        final end = (start + maxChars).clamp(0, paragraph.length);
        output.add(paragraph.substring(start, end));
        start = end;
      }
    }

    return output;
  }

  String _buildFtsQuery(String query) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 2)
        .toSet()
        .take(8)
        .toList();

    if (terms.isEmpty) {
      return '';
    }

    return terms.map((term) => '$term*').join(' ');
  }
}
