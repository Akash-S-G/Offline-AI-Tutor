import 'package:sqflite/sqflite.dart' as sqflite;
import '../data/educational_database.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';
import '../../../config/app_environment.dart';
import 'inverted_index.dart';

/// Search result with relevance score
class SearchResult {
  final String id; // Can be concept ID, chapter ID, or flashcard ID
  final String type; // 'concept', 'chapter', 'flashcard', 'quiz'
  final String title;
  final String content;
  final double relevanceScore; // 0.0 to 1.0
  final String? metadata; // JSON string with additional context

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.relevanceScore,
    this.metadata,
  });
}

/// Local search service using SQLite FTS5 (Full-Text Search)
/// 
/// Provides offline-first content search with:
/// - Full-text search across chapters, concepts, flashcards, quizzes
/// - Relevance scoring based on match frequency and type
/// - Confidence estimation for routing to backend
class LocalSearchService {
  static final LocalSearchService _instance = LocalSearchService._internal();

  factory LocalSearchService() {
    return _instance;
  }

  LocalSearchService._internal();

  /// Search for content in local database using FTS5
  /// 
  /// Returns list of SearchResult sorted by relevance (highest first)
  /// Empty list if no results found
  Future<List<SearchResult>> search(String query) async {
    try {
      AppEnvironment.log('SYNC', '[LocalSearch] Searching for: "$query"');

      if (query.trim().isEmpty) {
        return [];
      }

      final db = await EducationalDatabase.database;
      final normalizedQuery = _normalizeQuery(query);

      // Search in FTS table (full-text search)
        final ftsResults = EducationalDatabase.isFullTextSearchAvailable
            ? await _searchFTS(db, normalizedQuery)
            : <SearchResult>[];

        // If FTS isn't available, attempt the in-memory inverted index fallback
        final invertedResults = <SearchResult>[];
        if (!EducationalDatabase.isFullTextSearchAvailable) {
          final inv = InvertedIndexService();
          final raw = await inv.search(normalizedQuery);
          for (final r in raw) {
            final meta = r['meta'] as Map<String, dynamic>;
            invertedResults.add(SearchResult(
              id: meta['contentId'] as String,
              type: meta['type'] as String,
              title: meta['title'] as String,
              content: meta['content'] as String,
              relevanceScore: (r['score'] as double) / 10.0,
              metadata: null,
            ));
          }
        }

      // Also search in structured fields for additional results
      final structuredResults = await _searchStructured(db, normalizedQuery);

      // Combine and deduplicate results
      // Merge prioritized: FTS -> inverted index -> structured
      var combinedResults = <SearchResult>[];
      combinedResults.addAll(ftsResults);
      combinedResults.addAll(invertedResults);
      combinedResults = _mergeResults(combinedResults, structuredResults);

      // Sort by relevance score (descending)
      combinedResults.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      AppEnvironment.log(
        'SYNC',
        '[LocalSearch] Found ${combinedResults.length} results with avg confidence ${(combinedResults.isEmpty ? 0 : combinedResults.map((r) => r.relevanceScore).reduce((a, b) => a + b) / combinedResults.length).toStringAsFixed(2)}',
      );

      return combinedResults;
    } catch (e) {
      AppEnvironment.log('SYNC', '[LocalSearch] Error during search: $e');
      return [];
    }
  }

  /// Search in FTS5 virtual table
  Future<List<SearchResult>> _searchFTS(sqflite.Database db, String query) async {
    try {
      final results = await db.rawQuery(
        '''
        SELECT 
          type, 
          contentId, 
          title, 
          content,
          rank
        FROM content_fts 
        WHERE content_fts MATCH ?
        ORDER BY rank DESC
        LIMIT 50
        ''',
        [query],
      );

      final searchResults = <SearchResult>[];

      for (final row in results) {
        final type = row['type'] as String;
        final contentId = row['contentId'] as String;
        final title = row['title'] as String? ?? '';
        final content = row['content'] as String? ?? '';

        // Calculate relevance score (0.0 to 1.0)
        // Better matches have lower rank values (more negative)
        final rankValue = (row['rank'] as num?)?.toDouble() ?? 0;
        final relevanceScore = _calculateRelevanceScore(rankValue, content, query);

        searchResults.add(
          SearchResult(
            id: contentId,
            type: type,
            title: title,
            content: content.length > 200
                ? '${content.substring(0, 200)}...'
                : content,
            relevanceScore: relevanceScore,
          ),
        );
      }

      return searchResults;
    } catch (e) {
      AppEnvironment.log('SYNC', '[LocalSearch] FTS search error: $e');
      return [];
    }
  }

  /// Search in structured fields (concepts, flashcards, etc.)
  Future<List<SearchResult>> _searchStructured(
    sqflite.Database db,
    String query,
  ) async {
    try {
      final results = <SearchResult>[];

      // Search concepts by name and definition
      final conceptResults = await db.query(
        'concepts',
        where: 'name LIKE ? OR definition LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: 20,
      );

      for (final row in conceptResults) {
        final name = row['name'] as String? ?? '';
        final definition = row['definition'] as String? ?? '';
        final relevanceScore = _calculateFieldRelevance(name, definition, query);

        if (relevanceScore > 0.1) {
          results.add(
            SearchResult(
              id: row['id'].toString(),
              type: 'concept',
              title: name,
              content: definition.length > 200
                  ? '${definition.substring(0, 200)}...'
                  : definition,
              relevanceScore: relevanceScore,
            ),
          );
        }
      }

      // Search flashcards by term and definition
      final flashcardResults = await db.query(
        'flashcards',
        where: 'term LIKE ? OR definition LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: 20,
      );

      for (final row in flashcardResults) {
        final term = row['term'] as String? ?? '';
        final definition = row['definition'] as String? ?? '';
        final relevanceScore = _calculateFieldRelevance(term, definition, query);

        if (relevanceScore > 0.1) {
          results.add(
            SearchResult(
              id: row['id'].toString(),
              type: 'flashcard',
              title: term,
              content: definition.length > 200
                  ? '${definition.substring(0, 200)}...'
                  : definition,
              relevanceScore: relevanceScore,
            ),
          );
        }
      }

      // Search chapters by name and summary
      final chapterResults = await db.query(
        'chapters',
        where: 'name LIKE ? OR summary LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: 20,
      );

      for (final row in chapterResults) {
        final name = row['name'] as String? ?? '';
        final summary = row['summary'] as String? ?? '';
        final relevanceScore = _calculateFieldRelevance(name, summary, query);

        if (relevanceScore > 0.1) {
          results.add(
            SearchResult(
              id: row['id'].toString(),
              type: 'chapter',
              title: name,
              content: summary.length > 200
                  ? '${summary.substring(0, 200)}...'
                  : summary,
              relevanceScore: relevanceScore,
            ),
          );
        }
      }

      return results;
    } catch (e) {
      AppEnvironment.log('SYNC', '[LocalSearch] Structured search error: $e');
      return [];
    }
  }

  /// Merge FTS and structured results, keeping highest relevance score
  List<SearchResult> _mergeResults(
    List<SearchResult> ftsResults,
    List<SearchResult> structuredResults,
  ) {
    final merged = <String, SearchResult>{}; // Map by id to avoid duplicates

    for (final result in ftsResults) {
      merged[result.id] = result;
    }

    for (final result in structuredResults) {
      if (merged.containsKey(result.id)) {
        // Keep highest relevance score
        if (result.relevanceScore > merged[result.id]!.relevanceScore) {
          merged[result.id] = result;
        }
      } else {
        merged[result.id] = result;
      }
    }

    return merged.values.toList();
  }

  /// Calculate relevance score from FTS rank
  /// 
  /// FTS rank is negative (more negative = better match)
  /// Convert to 0.0-1.0 scale
  double _calculateRelevanceScore(double rankValue, String content, String query) {
    // Base score from rank (FTS rank is negative)
    double baseScore = 0.5 + (rankValue / 100).clamp(-0.4, 0.4);

    // Boost score if query appears in title/beginning of content
    final contentLower = content.toLowerCase();
    final queryLower = query.toLowerCase();

    if (contentLower.startsWith(queryLower)) {
      baseScore += 0.2;
    }

    // Count query occurrences for boost
    final occurrences = queryLower.allMatches(contentLower).length;
    baseScore += (occurrences * 0.05).clamp(0, 0.2);

    return baseScore.clamp(0.0, 1.0);
  }

  /// Calculate relevance score for structured field search
  double _calculateFieldRelevance(String field1, String field2, String query) {
    final queryLower = query.toLowerCase();
    final field1Lower = field1.toLowerCase();
    final field2Lower = field2.toLowerCase();

    double score = 0.0;

    // Exact match in field1 = high relevance
    if (field1Lower == queryLower) {
      score = 0.95;
    }
    // Query in field1 start = high relevance
    else if (field1Lower.startsWith(queryLower)) {
      score = 0.85;
    }
    // Query in field1 = medium-high relevance
    else if (field1Lower.contains(queryLower)) {
      score = 0.7;
    }
    // Query in field2 = medium relevance
    else if (field2Lower.contains(queryLower)) {
      score = 0.5;
    }

    // Boost based on field2 presence
    if (field2.isNotEmpty && score > 0) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Normalize search query
  /// - Convert to lowercase
  /// - Remove extra spaces
  /// - Handle special FTS characters
  String _normalizeQuery(String query) {
    return query
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('"', '')
        .replaceAll('*', '');
  }

  /// Get search confidence score for routing decision
  /// 
  /// Returns 0.0-1.0 indicating confidence that results are sufficient
  /// > 0.7 = use local results, < 0.7 = escalate to backend
  Future<double> calculateSearchConfidence(
    String query,
    List<SearchResult> results,
  ) async {
    if (results.isEmpty) {
      return 0.0; // No local results = low confidence
    }

    // Average relevance score of top results
    double avgRelevance = results
            .take(3)
            .fold(0.0, (sum, r) => sum + r.relevanceScore) /
        results.take(3).length;

    // Penalize small result sets
    double resultCountFactor = (results.length / 10).clamp(0.5, 1.0);

    // Combine factors
    final confidence = (avgRelevance + resultCountFactor) / 2;

    AppEnvironment.log(
      'SYNC',
      '[LocalSearch] Confidence: ${confidence.toStringAsFixed(2)} (${results.length} results, avg relevance: ${avgRelevance.toStringAsFixed(2)})',
    );

    return confidence;
  }

  /// Get chapter context for LLM inference
  /// 
  /// Loads chapter content needed for answering question
  Future<ChapterContextData?> getChapterContext(
    String chapterId,
    List<ConceptModel> relatedConcepts,
  ) async {
    try {
      final chapterIdInt = int.tryParse(chapterId);
      if (chapterIdInt == null) return null;

      final chapter = await EducationalRepository.getChapterById(chapterIdInt);
      if (chapter == null) return null;

      return ChapterContextData(
        chapter: chapter,
        concepts: relatedConcepts,
        estimatedTokens: _estimateTokenCount(chapter),
      );
    } catch (e) {
      AppEnvironment.log('SYNC', '[LocalSearch] Error loading chapter context: $e');
      return null;
    }
  }

  /// Estimate token count for content (rough approximation)
  int _estimateTokens(String text) {
    // Rough estimate: ~4 characters per token
    return (text.length / 4).ceil();
  }

  /// Estimate total tokens for chapter context
  int _estimateTokenCount(ChapterModel chapter) {
    int tokens = 0;
    tokens += _estimateTokens(chapter.name);
    tokens += _estimateTokens(chapter.summary ?? '');
    tokens += _estimateTokens(chapter.content ?? '');
    return tokens;
  }
}

/// Chapter context data for LLM inference
class ChapterContextData {
  final ChapterModel chapter;
  final List<ConceptModel> concepts;
  final int estimatedTokens;

  ChapterContextData({
    required this.chapter,
    required this.concepts,
    required this.estimatedTokens,
  });

  /// Get formatted context string for LLM
  String getFormattedContext() {
    final buffer = StringBuffer();

    buffer.writeln('# ${chapter.name}');
    buffer.writeln();

    if (chapter.summary != null) {
      buffer.writeln('## Summary');
      buffer.writeln(chapter.summary);
      buffer.writeln();
    }

    if (chapter.content != null) {
      buffer.writeln('## Content');
      buffer.writeln(chapter.content);
      buffer.writeln();
    }

    if (concepts.isNotEmpty) {
      buffer.writeln('## Key Concepts');
      for (final concept in concepts) {
        buffer.writeln('- **${concept.name}**: ${concept.definition ?? ""}');
        if (concept.examples != null) {
          buffer.writeln('  Example: ${concept.examples}');
        }
      }
    }

    return buffer.toString();
  }
}
