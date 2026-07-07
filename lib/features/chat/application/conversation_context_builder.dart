import 'package:shared_preferences/shared_preferences.dart';

import '../domain/tutor_message.dart';
import 'prompt_budget_manager.dart';

class ConversationContext {
  const ConversationContext({
    required this.sessionSummary,
    required this.recentConversation,
  });

  final String sessionSummary;
  final List<String> recentConversation;

  List<String> get promptLines => <String>[
    if (sessionSummary.trim().isNotEmpty) 'Session Summary:\n$sessionSummary',
    if (recentConversation.isNotEmpty)
      'Recent Conversation:\n${recentConversation.join('\n')}',
  ];
}

class ConversationContextBuilder {
  const ConversationContextBuilder({
    this.recentExchangeCount = 5,
    this.summaryTriggerMessages = 10,
    this.budget = const PromptBudgetManager(),
  });

  final int recentExchangeCount;
  final int summaryTriggerMessages;
  final PromptBudgetManager budget;

  Future<ConversationContext> build({
    required String sessionId,
    required List<TutorMessage> messages,
    required String currentQuestion,
    required String subject,
    required String chapter,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _summaryKey(sessionId);
    final meaningful = _meaningfulMessages(messages, currentQuestion);

    var summary = prefs.getString(key)?.trim() ?? '';
    if (meaningful.length >= summaryTriggerMessages) {
      summary = _summarize(
        messages: meaningful,
        subject: subject,
        chapter: chapter,
      );
      await prefs.setString(key, summary);
    }

    final recentLines = _recentConversationLines(meaningful);
    return ConversationContext(
      sessionSummary: budget.clip(summary, budget.summaryChars),
      recentConversation: budget.fitLines(recentLines, budget.historyChars),
    );
  }

  List<TutorMessage> _meaningfulMessages(
    List<TutorMessage> messages,
    String currentQuestion,
  ) {
    final normalizedQuestion = _normalize(currentQuestion);
    final meaningful = messages
        .where((message) => message.text.trim().isNotEmpty)
        .where((message) => !_isNoisyHistoryMessage(message.text))
        .toList(growable: true);

    if (meaningful.isNotEmpty &&
        meaningful.last.isUser &&
        _normalize(meaningful.last.text) == normalizedQuestion) {
      meaningful.removeLast();
    }

    return meaningful;
  }

  List<String> _recentConversationLines(List<TutorMessage> messages) {
    if (messages.isEmpty) {
      return const <String>[];
    }

    final maxMessages = (recentExchangeCount.clamp(3, 5) * 2).clamp(6, 10);
    final recent = messages.length <= maxMessages
        ? messages
        : messages.sublist(messages.length - maxMessages);

    final lines = <String>[];
    String? lastKey;
    var duplicateCount = 0;

    for (final message in recent) {
      final role = message.isUser ? 'Student' : 'Tutor';
      final text = budget.clip(message.text, 220);
      final key = '$role:${_normalize(text)}';
      if (key == lastKey) {
        duplicateCount += 1;
        if (duplicateCount > 1) {
          continue;
        }
      } else {
        duplicateCount = 0;
        lastKey = key;
      }
      lines.add('$role: $text');
    }

    return lines;
  }

  String _summarize({
    required List<TutorMessage> messages,
    required String subject,
    required String chapter,
  }) {
    final studentText = messages
        .where((message) => message.isUser)
        .map((message) => message.text)
        .join(' ');
    final tutorText = messages
        .where((message) => !message.isUser)
        .map((message) => message.text)
        .join(' ');

    final understood = _keywords(tutorText).take(4).toList();
    final struggles = _struggleTerms(studentText).take(3).toList();

    final lines = <String>[
      'Subject: $subject',
      'Current Topic: $chapter',
      if (understood.isNotEmpty)
        'Student understands: ${understood.join(', ')}',
      if (struggles.isNotEmpty)
        'Student struggles with: ${struggles.join(', ')}',
    ];

    if (lines.length <= 2) {
      lines.add('Student is learning $chapter.');
    }

    return lines.join('\n');
  }

  Iterable<String> _struggleTerms(String text) sync* {
    final lower = text.toLowerCase();
    final patterns = <RegExp>[
      RegExp(
        r"(?:don't understand|do not understand|confused about|why does|how does|what is)\s+([a-z0-9 ]{3,40})",
      ),
      RegExp(
        r'(?:struggle|stuck|confused)\s+(?:with|on|about)?\s*([a-z0-9 ]{3,40})',
      ),
    ];

    final seen = <String>{};
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(lower)) {
        final term = _cleanTopic(match.group(1) ?? '');
        if (term.isNotEmpty && seen.add(term)) {
          yield term;
        }
      }
    }
  }

  Iterable<String> _keywords(String text) {
    final stopWords = <String>{
      'about',
      'after',
      'also',
      'answer',
      'because',
      'chapter',
      'does',
      'example',
      'from',
      'have',
      'into',
      'learning',
      'means',
      'more',
      'question',
      'student',
      'that',
      'their',
      'there',
      'this',
      'when',
      'where',
      'which',
      'with',
      'your',
    };

    final counts = <String, int>{};
    for (final token in text.toLowerCase().split(RegExp(r'[^a-z0-9]+'))) {
      if (token.length < 4 || stopWords.contains(token)) {
        continue;
      }
      counts[token] = (counts[token] ?? 0) + 1;
    }

    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.map((entry) => entry.key);
  }

  String _cleanTopic(String value) {
    return value
        .replaceAll(RegExp(r'\b(the|a|an|it|this|that|please|again)\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _summaryKey(String sessionId) => 'chat_session_summary_v1_$sessionId';

  bool _isNoisyHistoryMessage(String text) {
    final lower = text.toLowerCase();
    return lower.contains('educational context:') ||
        lower.contains('priority context:') ||
        lower.contains('session summary:') ||
        lower.contains('recent conversation:') ||
        lower.contains('relevant notes:') ||
        lower.contains('student question:') ||
        lower.contains('tutor answer:') ||
        lower.contains('answer:') && lower.contains('question:') ||
        lower.contains('failed to process your question') ||
        lower.contains('please try again') ||
        lower.contains('context:') && lower.contains('[source') ||
        lower.startsWith('session memory reset') ||
        lower.startsWith('you are learning ') ||
        lower.contains('ask your doubt to start');
  }
}
