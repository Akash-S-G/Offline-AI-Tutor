import '../data/local/rag_repository.dart';
import '../domain/rag_chunk.dart';

class RetrievedContextItem {
  const RetrievedContextItem({
    required this.chunkId,
    required this.sourceTitle,
    required this.content,
    required this.score,
    required this.confidence,
  });

  final String chunkId;
  final String sourceTitle;
  final String content;
  final int score;
  final double confidence;
}

class SimpleRagService {
  SimpleRagService({required RagRepository repository}) : _repository = repository;

  final RagRepository _repository;

  Future<List<String>> retrieveContext({
    required String chapterId,
    required String query,
    int topK = 3,
    int? maxContextChars,
  }) async {
    final detailed = await retrieveContextDetailed(
      chapterId: chapterId,
      query: query,
      topK: topK,
      maxContextChars: maxContextChars,
    );

    return detailed
        .map(
          (item) => '[Source: ${item.sourceTitle} | confidence ${(item.confidence * 100).round()}%] ${item.content}',
        )
        .toList();
  }

  Future<List<RetrievedContextItem>> retrieveContextDetailed({
    required String chapterId,
    required String query,
    int topK = 3,
    int? maxContextChars,
  }) async {
    final ftsChunks = await _repository.searchChunksForChapter(
      chapterId: chapterId,
      query: query,
      limit: topK * 8,
    );

    final chunks = ftsChunks.isEmpty
        ? await _repository.getChunksForChapter(chapterId)
        : ftsChunks;

    if (chunks.isEmpty) {
      return const [];
    }

    final queryTerms = _tokenize(query);
    if (queryTerms.isEmpty) {
      final budgeted = _applyContextBudget(
        chunks.take(topK).toList(),
        budgetChars: maxContextChars ?? _dynamicContextBudget(query: query, topK: topK),
      );
      return budgeted
          .map(
            (e) => RetrievedContextItem(
              chunkId: e.id,
              sourceTitle: e.sourceTitle,
              content: e.content,
              score: 1,
              confidence: 0.3,
            ),
          )
          .toList();
    }

    final ranked = chunks
        .asMap()
        .entries
        .map(
          (entry) => (
            chunk: entry.value,
            score: _scoreChunk(
              queryTerms: queryTerms,
              chunk: entry.value,
              fullQuery: query,
              ftsPosition: entry.key,
            ),
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final filtered = ranked.where((e) => e.score > 0).toList();
    final selectedCandidates = filtered.isEmpty
        ? chunks.take(topK).toList()
        : filtered.take(topK * 3).map((e) => e.chunk).toList();

    final deduped = _suppressNearDuplicates(selectedCandidates);
    final selected = _applyContextBudget(
      deduped.take(topK).toList(),
      budgetChars: maxContextChars ?? _dynamicContextBudget(query: query, topK: topK),
    );

    final maxScore = filtered.isEmpty ? 1 : filtered.first.score;
    final scoreById = {
      for (final item in filtered) item.chunk.id: item.score,
    };

    return selected
        .map(
          (e) {
            final score = scoreById[e.id] ?? 1;
            final confidence = (score / (maxScore == 0 ? 1 : maxScore))
                .clamp(0.0, 1.0)
                .toDouble();
            return RetrievedContextItem(
              chunkId: e.id,
              sourceTitle: e.sourceTitle,
              content: e.content,
              score: score,
              confidence: confidence,
            );
          },
        )
        .toList();
  }

  int _dynamicContextBudget({required String query, required int topK}) {
    final queryTerms = _tokenize(query);
    final base = 1100;
    final queryBoost = queryTerms.length * 70;
    final topKBoost = topK * 140;
    return (base + queryBoost + topKBoost).clamp(900, 2600);
  }

  int _scoreChunk({
    required Set<String> queryTerms,
    required RagChunk chunk,
    required String fullQuery,
    required int ftsPosition,
  }) {
    final content = chunk.content.toLowerCase();
    var score = 0;

    for (final term in queryTerms) {
      final occurrences = RegExp(RegExp.escape(term)).allMatches(content).length;
      score += occurrences * 3;
    }

    final fullLower = fullQuery.toLowerCase().trim();
    if (fullLower.isNotEmpty && content.contains(fullLower)) {
      score += 6;
    }

    final positionBoost = (10 - ftsPosition).clamp(0, 10);
    score += positionBoost;

    return score;
  }

  List<RagChunk> _suppressNearDuplicates(List<RagChunk> chunks) {
    final selected = <RagChunk>[];

    for (final chunk in chunks) {
      final duplicate = selected.any(
        (existing) => _similarity(existing.content, chunk.content) >= 0.85,
      );
      if (!duplicate) {
        selected.add(chunk);
      }
    }

    return selected;
  }

  List<RagChunk> _applyContextBudget(
    List<RagChunk> chunks, {
    required int budgetChars,
  }) {
    var used = 0;
    final output = <RagChunk>[];

    for (final chunk in chunks) {
      final content = chunk.content.trim();
      if (content.isEmpty) {
        continue;
      }

      if (used + content.length > budgetChars && output.isNotEmpty) {
        break;
      }

      output.add(chunk);
      used += content.length;
    }

    return output;
  }

  double _similarity(String a, String b) {
    final sa = _tokenize(a);
    final sb = _tokenize(b);
    if (sa.isEmpty || sb.isEmpty) {
      return 0;
    }

    final intersection = sa.intersection(sb).length;
    final union = sa.union(sb).length;
    if (union == 0) {
      return 0;
    }
    return intersection / union;
  }

  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((e) => e.length > 2)
        .toSet();
  }
}
