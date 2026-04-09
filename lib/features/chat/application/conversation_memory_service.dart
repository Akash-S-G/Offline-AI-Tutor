import '../data/local/chat_memory_policy_repository.dart';
import '../domain/tutor_message.dart';

class ConversationMemoryResult {
  const ConversationMemoryResult({
    required this.shortTermMessages,
    required this.semanticMessages,
    required this.combinedLines,
  });

  final List<TutorMessage> shortTermMessages;
  final List<TutorMessage> semanticMessages;
  final List<String> combinedLines;
}

class ConversationMemoryService {
  const ConversationMemoryService();

  ConversationMemoryResult buildMemory(
    List<TutorMessage> sessionMessages, {
    required String question,
    required ChatMemoryPolicy policy,
  }) {
    final meaningful = sessionMessages
        .where((m) => m.text.trim().isNotEmpty)
        .toList(growable: false);

    if (meaningful.isEmpty) {
      return const ConversationMemoryResult(
        shortTermMessages: <TutorMessage>[],
        semanticMessages: <TutorMessage>[],
        combinedLines: <String>[],
      );
    }

    final shortWindow = policy.shortTermWindow.clamp(2, 30);
    final shortTerm = meaningful.length <= shortWindow
        ? meaningful
        : meaningful.sublist(meaningful.length - shortWindow);

    final semantic = _pickSemanticMemories(
      allMessages: meaningful,
      shortTerm: shortTerm,
      question: question,
      enabled: policy.semanticRecallEnabled,
      topK: policy.semanticTopK,
    );

    final merged = <TutorMessage>[];
    final seen = <String>{};

    for (final item in <TutorMessage>[...semantic, ...shortTerm]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp))) {
      final key = '${item.isUser ? 'u' : 'a'}:${_normalize(item.text)}';
      if (seen.add(key)) {
        merged.add(item);
      }
    }

    final compact = _compressMemoryLines(merged);
    final lines = compact
        .map((m) {
          final base = '${m.role}: ${_clip(m.text, 240)}';
          return m.count > 1 ? '$base (x${m.count})' : base;
        })
        .toList(growable: false);

    return ConversationMemoryResult(
      shortTermMessages: shortTerm,
      semanticMessages: semantic,
      combinedLines: lines,
    );
  }

  List<TutorMessage> _pickSemanticMemories({
    required List<TutorMessage> allMessages,
    required List<TutorMessage> shortTerm,
    required String question,
    required bool enabled,
    required int topK,
  }) {
    if (!enabled || topK <= 0) {
      return const <TutorMessage>[];
    }

    final excluded = shortTerm
        .map((m) => m.timestamp.microsecondsSinceEpoch.toString())
        .toSet();

    final queryTokens = _tokenize(question);
    if (queryTokens.isEmpty) {
      return const <TutorMessage>[];
    }

    final candidates = allMessages.where((m) {
      return !excluded.contains(m.timestamp.microsecondsSinceEpoch.toString());
    }).toList(growable: false);

    if (candidates.isEmpty) {
      return const <TutorMessage>[];
    }

    final scored = candidates
        .map((m) {
          final score = _semanticScore(queryTokens, m.text);
          return (message: m, score: score);
        })
        .where((entry) => entry.score > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    if (scored.isEmpty) {
      return const <TutorMessage>[];
    }

    return scored
        .take(topK.clamp(1, 8))
        .map((entry) => entry.message)
        .toList(growable: false);
  }

  int _semanticScore(Set<String> queryTokens, String text) {
    final textTokens = _tokenize(text);
    if (textTokens.isEmpty) {
      return 0;
    }

    final overlap = queryTokens.intersection(textTokens).length;
    if (overlap == 0) {
      return 0;
    }

    final union = queryTokens.union(textTokens).length;
    final jaccardScaled = union == 0 ? 0 : ((overlap * 1000) ~/ union);

    final phraseBoost = text.toLowerCase().contains(queryTokens.join(' ')) ? 120 : 0;
    return (overlap * 100) + jaccardScaled + phraseBoost;
  }

  List<_CompressedMemoryLine> _compressMemoryLines(List<TutorMessage> merged) {
    if (merged.isEmpty) {
      return const <_CompressedMemoryLine>[];
    }

    final ordered = merged
        .map(
          (m) => _CompressedMemoryLine(
            role: m.isUser ? 'Student' : 'Tutor',
            text: m.text.trim(),
            normalized: _normalize(m.text),
            count: 1,
          ),
        )
        .toList(growable: false);

    final collapsedRuns = <_CompressedMemoryLine>[];
    for (final line in ordered) {
      if (collapsedRuns.isNotEmpty) {
        final prev = collapsedRuns.last;
        if (prev.role == line.role && prev.normalized == line.normalized) {
          collapsedRuns[collapsedRuns.length - 1] = _CompressedMemoryLine(
            role: prev.role,
            text: prev.text,
            normalized: prev.normalized,
            count: prev.count + 1,
          );
          continue;
        }
      }
      collapsedRuns.add(line);
    }

    final maxLines = 8;
    if (collapsedRuns.length <= maxLines) {
      return collapsedRuns;
    }
    return collapsedRuns.sublist(collapsedRuns.length - maxLines);
  }

  Set<String> _tokenize(String input) {
    return input
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length > 2)
        .toSet();
  }

  String _clip(String value, int maxChars) {
    final clean = value.trim();
    if (clean.length <= maxChars) {
      return clean;
    }
    return '${clean.substring(0, maxChars)}...';
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _CompressedMemoryLine {
  const _CompressedMemoryLine({
    required this.role,
    required this.text,
    required this.normalized,
    required this.count,
  });

  final String role;
  final String text;
  final String normalized;
  final int count;
}
