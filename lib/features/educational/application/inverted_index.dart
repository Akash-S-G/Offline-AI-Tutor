import 'dart:async';

import '../data/educational_database.dart';
import '../../../config/app_environment.dart';

/// Lightweight inverted index built in memory (with optional on-disk cache)
/// Used when SQLite FTS5 is not available on the device.
class InvertedIndexService {
  static final InvertedIndexService _instance = InvertedIndexService._internal();

  factory InvertedIndexService() => _instance;

  InvertedIndexService._internal();

  final Map<String, List<_Posting>> _index = {};
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> buildIndex() async {
    try {
      AppEnvironment.log('SYNC', '[InvertedIndex] Building index from DB');

      final db = await EducationalDatabase.database;

      _index.clear();

      // Load concepts
      final concepts = await db.query('concepts');
      for (final row in concepts) {
        final id = row['id'].toString();
        final title = (row['name'] as String?) ?? '';
        final content = ((row['definition'] as String?) ?? '') + ' ' + ((row['examples'] as String?) ?? '');
        _addDocument('concept', id, title, content);
      }

      // Load chapters
      final chapters = await db.query('chapters');
      for (final row in chapters) {
        final id = row['id'].toString();
        final title = (row['name'] as String?) ?? '';
        final content = ((row['summary'] as String?) ?? '') + ' ' + ((row['content'] as String?) ?? '');
        _addDocument('chapter', id, title, content);
      }

      // Load flashcards
      final flashcards = await db.query('flashcards');
      for (final row in flashcards) {
        final id = row['id'].toString();
        final title = (row['term'] as String?) ?? '';
        final content = (row['definition'] as String?) ?? '';
        _addDocument('flashcard', id, title, content);
      }

      _ready = true;
      AppEnvironment.log('SYNC', '[InvertedIndex] Built ${_index.length} tokens');
    } catch (e) {
      AppEnvironment.log('SYNC', '[InvertedIndex] Error building index: $e');
      _ready = false;
    }
  }

  void _addDocument(String type, String id, String title, String content) {
    final docText = '$title\n$content'.toLowerCase();
    final tokens = _tokenize(docText);
    final counts = <String, int>{};
    for (final t in tokens) {
      counts[t] = (counts[t] ?? 0) + 1;
    }

    for (final entry in counts.entries) {
      final token = entry.key;
      final count = entry.value;
      _index.putIfAbsent(token, () => []).add(_Posting(type: type, id: id, title: title, contentSnippet: _snippet(content, token), weight: count));
    }
  }

  List<String> _tokenize(String text) {
    final tokens = <String>[];
    final parts = text.split(RegExp(r"[^a-z0-9]+"));
    for (final p in parts) {
      final t = p.trim();
      if (t.isEmpty) continue;
      if (t.length < 2) continue;
      tokens.add(t);
    }
    return tokens;
  }

  String _snippet(String content, String token) {
    final lc = content.toLowerCase();
    final idx = lc.indexOf(token);
    if (idx < 0) return content.length > 120 ? content.substring(0, 120) + '...' : content;
    final start = idx - 40 < 0 ? 0 : idx - 40;
    final end = (idx + 80) > content.length ? content.length : idx + 80;
    return content.substring(start, end) + (end < content.length ? '...' : '');
  }

  /// Search the inverted index for a query. Returns list of simple maps similar to SearchResult.
  Future<List<Map<String, dynamic>>> search(String query, {int limit = 50}) async {
    if (!_ready) await buildIndex();

    final qtokens = _tokenize(query.toLowerCase());
    final scoreMap = <String, double>{};
    final metaMap = <String, Map<String, dynamic>>{};

    for (final t in qtokens) {
      final postings = _index[t] ?? [];
      for (final p in postings) {
        final key = '${p.type}:${p.id}';
        scoreMap[key] = (scoreMap[key] ?? 0) + (p.weight.toDouble());
        metaMap[key] = {
          'type': p.type,
          'contentId': p.id,
          'title': p.title,
          'content': p.contentSnippet,
        };
      }
    }

    final results = scoreMap.entries.map((e) {
      final meta = metaMap[e.key]!;
      return {'score': e.value, 'meta': meta};
    }).toList();

    results.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return results.take(limit).toList();
  }
}

class _Posting {
  final String type;
  final String id;
  final String title;
  final String contentSnippet;
  final int weight;

  _Posting({required this.type, required this.id, required this.title, required this.contentSnippet, required this.weight});
}
