import 'dart:convert';

import '../data/tutor_inference_gateway.dart';
import '../data/local/chat_benchmark_repository.dart';

class ChatBenchmarkProgress {
  const ChatBenchmarkProgress({
    required this.completed,
    required this.total,
    required this.lastItem,
  });

  final int completed;
  final int total;
  final ChatBenchmarkItem? lastItem;
}

class ChatBenchmarkSummary {
  const ChatBenchmarkSummary({
    required this.runId,
    required this.avgTtftMs,
    required this.avgTotalMs,
    required this.avgTokensPerSec,
    required this.items,
  });

  final int runId;
  final int avgTtftMs;
  final int avgTotalMs;
  final double avgTokensPerSec;
  final List<ChatBenchmarkItem> items;
}

class ChatBenchmarkComparison {
  const ChatBenchmarkComparison({
    required this.current,
    required this.previous,
    required this.deltaTtftMs,
    required this.deltaTotalMs,
    required this.deltaTokensPerSec,
  });

  final ChatBenchmarkRun current;
  final ChatBenchmarkRun? previous;
  final int deltaTtftMs;
  final int deltaTotalMs;
  final double deltaTokensPerSec;
}

class ChatLatencyBenchmarkService {
  ChatLatencyBenchmarkService({
    required TutorInferenceGateway gateway,
    ChatBenchmarkRepository? repository,
  })  : _gateway = gateway,
        _repository = repository ?? ChatBenchmarkRepository();

  final TutorInferenceGateway _gateway;
  final ChatBenchmarkRepository _repository;

  Stream<ChatBenchmarkProgress> runBenchmark({
    required String chapterId,
    required String mode,
    required List<String> prompts,
  }) async* {
    final items = <ChatBenchmarkItem>[];

    for (var i = 0; i < prompts.length; i++) {
      final prompt = prompts[i].trim();
      if (prompt.isEmpty) {
        continue;
      }

      final item = await _runSingle(prompt);
      items.add(item);
      yield ChatBenchmarkProgress(
        completed: i + 1,
        total: prompts.length,
        lastItem: item,
      );
    }

    if (items.isEmpty) {
      throw Exception('No benchmark prompts were executed.');
    }

    await _repository.saveRun(
      chapterId: chapterId,
      mode: mode,
      items: items,
      notes: 'Auto benchmark run',
    );
  }

  Future<ChatBenchmarkSummary> getLatestSummary({
    required String chapterId,
    required String mode,
  }) async {
    final run = await _repository.getLatestRun(chapterId: chapterId, mode: mode);
    if (run == null) {
      throw Exception('No benchmark run found for this chapter/mode.');
    }

    final items = await _repository.getItemsForRun(run.id);

    return ChatBenchmarkSummary(
      runId: run.id,
      avgTtftMs: run.avgTtftMs,
      avgTotalMs: run.avgTotalMs,
      avgTokensPerSec: run.avgTokensPerSec,
      items: items,
    );
  }

  Future<ChatBenchmarkComparison> getLatestComparison({
    required String chapterId,
    required String mode,
  }) async {
    final runs = await _repository.getRecentRuns(
      chapterId: chapterId,
      mode: mode,
      limit: 2,
    );

    if (runs.isEmpty) {
      throw Exception('No benchmark runs found.');
    }

    final current = runs.first;
    final previous = runs.length > 1 ? runs[1] : null;

    return ChatBenchmarkComparison(
      current: current,
      previous: previous,
      deltaTtftMs: previous == null ? 0 : current.avgTtftMs - previous.avgTtftMs,
      deltaTotalMs: previous == null ? 0 : current.avgTotalMs - previous.avgTotalMs,
      deltaTokensPerSec: previous == null ? 0 : current.avgTokensPerSec - previous.avgTokensPerSec,
    );
  }

  Future<ChatBenchmarkItem> _runSingle(String prompt) async {
    final startedAt = DateTime.now();
    DateTime? firstTokenAt;
    int totalTokens = 0;
    int totalMs = 0;
    int ttftMs = 0;
    double estimatedTokensPerSec = 0;

    await for (final chunk in _gateway.streamResponse(prompt: prompt)) {
      if (firstTokenAt == null && chunk.trim().isNotEmpty) {
        firstTokenAt = DateTime.now();
      }

      final metrics = _tryParseMetrics(chunk);
      if (metrics != null) {
        totalMs = metrics.totalMs;
        totalTokens = metrics.tokens;
        estimatedTokensPerSec = metrics.tokensPerSec;
        continue;
      }

      totalTokens += _estimateTokenCount(chunk);
    }

    final finishedAt = DateTime.now();

    ttftMs = firstTokenAt == null
        ? finishedAt.difference(startedAt).inMilliseconds
        : firstTokenAt.difference(startedAt).inMilliseconds;

    if (totalMs <= 0) {
      totalMs = finishedAt.difference(startedAt).inMilliseconds;
    }

    final tokensPerSec = estimatedTokensPerSec > 0
        ? estimatedTokensPerSec.toDouble()
      : (totalMs <= 0 ? 0.0 : (totalTokens * 1000.0 / totalMs));

    return ChatBenchmarkItem(
      promptText: prompt,
      ttftMs: ttftMs,
      totalMs: totalMs,
      tokens: totalTokens,
      tokensPerSec: tokensPerSec,
    );
  }

  _NativeMetrics? _tryParseMetrics(String chunk) {
    final trimmed = chunk.trimLeft();
    if (!trimmed.startsWith('{"type":"metrics"')) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      if (decoded['type'] != 'metrics') {
        return null;
      }

      return _NativeMetrics(
        totalMs: decoded['totalMs'] as int? ?? 0,
        tokens: decoded['tokens'] as int? ?? 0,
        tokensPerSec: (decoded['tokensPerSec'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (_) {
      return null;
    }
  }

  int _estimateTokenCount(String text) {
    if (text.trim().isEmpty) {
      return 0;
    }
    return (text.length / 4).round();
  }
}

class _NativeMetrics {
  const _NativeMetrics({
    required this.totalMs,
    required this.tokens,
    required this.tokensPerSec,
  });

  final int totalMs;
  final int tokens;
  final double tokensPerSec;
}
