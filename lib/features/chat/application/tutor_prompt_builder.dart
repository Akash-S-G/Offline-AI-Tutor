import '../../course/domain/course_tree.dart';
import 'conversation_context_builder.dart';
import 'prompt_budget_manager.dart';

class TutorPromptBuilder {
  TutorPromptBuilder({PromptBudgetManager? budget})
    : _budget = budget ?? const PromptBudgetManager();

  final PromptBudgetManager _budget;
  Map<String, dynamic> lastAudit = const <String, dynamic>{};

  String buildChapterPrompt({
    required Course course,
    required Subject subject,
    required Chapter chapter,
    required String question,
    required String languageCode,
    required List<String> retrievedContext,
    required ConversationContext conversationContext,
    Map<String, dynamic>? experimentContext,
  }) {
    final isKannada = languageCode == 'kn';
    final tutorLanguage = isKannada
        ? 'Kannada in natural school-level language. Use Kannada script by default. Keep only essential scientific names, formulas, and fixed technical terms in English when Kannada terms would be unclear.'
        : 'English';
    final systemPrompt = _budget.clip('''
You are an educational tutor.
Answer only the student's question.
Use the current subject, chapter, and recent conversation as support.
Do not repeat the question, the context labels, or any prompt text.
Keep explanations age appropriate, direct, and clear.
If the question is ambiguous, interpret it using the current learning topic.
Do not reveal internal reasoning or chain of thought.
If the active language is Kannada, answer in Kannada unless the student explicitly asks for English.
If the question mixes English and Kannada, respond naturally in Kannada and preserve formulas, names, and symbols.
''', _budget.systemChars);

    final curriculumSection = _budget.clip('''
Course: ${course.name}
Subject: ${subject.name}
Chapter: ${chapter.title}
Language: $tutorLanguage
Chapter Summary: ${chapter.summary}
''', _budget.curriculumChars);

    final summarySection = conversationContext.sessionSummary.trim().isEmpty
        ? 'Session summary: none yet.'
        : 'Session summary:\n${_budget.clip(conversationContext.sessionSummary, _budget.summaryChars)}';

    final historySection = conversationContext.recentConversation.isEmpty
        ? 'Recent conversation: none yet.'
        : 'Recent conversation:\n${_budget.fitLines(conversationContext.recentConversation, _budget.historyChars).join('\n')}';

    final ragItems = _budget.fitLines(
      retrievedContext
          .take(3)
          .toList()
          .asMap()
          .entries
          .map(
            (entry) =>
                '[Context ${entry.key + 1}] ${_budget.clip(entry.value, 820)}',
          )
          .toList(),
      _budget.ragChars,
    );
    final contextSection = ragItems.isEmpty
        ? 'Relevant notes: none yet. Use the chapter summary and standard textbook logic.'
        : 'Relevant notes:\n${ragItems.join('\n')}';

    final experimentSection =
        experimentContext == null || experimentContext.isEmpty
        ? ''
        : '\nActive Experiment State:\n$experimentContext\n';

    final prompt = _budget.hardCapPrompt('''
$systemPrompt

$curriculumSection
$experimentSection
$summarySection

$historySection

$contextSection

Rules:
1. Answer in simple words.
2. Use the subject, chapter, summary, recent conversation, and notes in that order.
3. Do not repeat the question or the context labels.
4. Do not include tags like <think>, <reasoning>, <analysis>, <|Question|>, <|Answer|>, or <|Roleplay|>.
5. Return only the final answer.

Student question: ${_budget.clip(question, _budget.questionChars)}
Answer:
''');

    lastAudit = <String, dynamic>{
      'subject': subject.name,
      'chapter': chapter.title,
      'summary_chars': conversationContext.sessionSummary.length,
      'history_chars': conversationContext.recentConversation.join('\n').length,
      'rag_chunks': ragItems.length,
      'rag_chars': ragItems.join('\n').length,
      'prompt_chars': prompt.length,
      'estimated_tokens': _budget.estimateTokens(prompt),
      'session_summary': conversationContext.sessionSummary,
      'recent_conversation': conversationContext.recentConversation,
      'retrieved_chunks': ragItems,
      'final_prompt': prompt,
    };

    return prompt;
  }
}
