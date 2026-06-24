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
    final tutorLanguage = languageCode == 'kn'
        ? 'Kannada with simple English terms'
        : 'English';
    final systemPrompt = _budget.clip('''
You are an educational tutor.
Use the current subject, chapter and recent conversation when answering.
Prefer curriculum content before general knowledge.
Keep explanations age appropriate.
Answer directly and clearly.
If the question is ambiguous, interpret it using the current learning topic.
Do not reveal internal reasoning.
Do not output chain of thought.
Provide only the final answer.
''', _budget.systemChars);

    final curriculumSection = _budget.clip('''
Course: ${course.name}
Subject: ${subject.name}
Chapter: ${chapter.title}
Language: $tutorLanguage
Chapter Summary: ${chapter.summary}
''', _budget.curriculumChars);

    final summarySection = conversationContext.sessionSummary.trim().isEmpty
        ? 'Session Summary:\nNo compact session summary is available yet.'
        : 'Session Summary:\n${_budget.clip(conversationContext.sessionSummary, _budget.summaryChars)}';

    final historySection = conversationContext.recentConversation.isEmpty
        ? 'Recent Conversation:\nNo prior conversation available for this session.'
        : 'Recent Conversation:\n${_budget.fitLines(conversationContext.recentConversation, _budget.historyChars).join('\n')}';

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
        ? 'Relevant Notes:\nNo syllabus notes available for this chapter yet. Use chapter summary and standard textbook logic.'
        : 'Relevant Notes:\n${ragItems.join('\n')}';

    final experimentSection =
        experimentContext == null || experimentContext.isEmpty
        ? ''
        : '\nActive Experiment State:\n$experimentContext\n';

    final prompt = _budget.hardCapPrompt('''
$systemPrompt

Priority Context:
1. Subject and chapter
$curriculumSection
$experimentSection
2. Session summary
$summarySection

3. Recent conversation
$historySection

4. Curriculum retrieval
$contextSection

Rules:
1. Answer in simple words.
2. Use the subject, chapter, summary, recent conversation, and notes in that order.
3. Do not repeat the question.
4. Do not include tags like <think>, <reasoning>, <analysis>, <|Question|>, <|Answer|>, or <|Roleplay|>.

Student Question: ${_budget.clip(question, _budget.questionChars)}
Tutor Answer:
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
