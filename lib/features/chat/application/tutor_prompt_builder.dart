import '../../course/domain/course_tree.dart';

class TutorPromptBuilder {
  String buildChapterPrompt({
    required Course course,
    required Subject subject,
    required Chapter chapter,
    required String question,
    required String languageCode,
    required List<String> retrievedContext,
    required List<String> conversationMemory,
  }) {
    final tutorLanguage = languageCode == 'kn' ? 'Kannada with simple English terms' : 'English';
    final contextSection = retrievedContext.isEmpty
        ? 'No syllabus notes available for this chapter yet. Use chapter summary and standard textbook logic.'
        : retrievedContext
            .take(2)
        .toList()
            .asMap()
            .entries
            .map((entry) => '[Context ${entry.key + 1}] ${_clip(entry.value, 600)}')
            .join('\n');

        final memorySection = conversationMemory.isEmpty
          ? 'No prior conversation memory available for this session.'
          : conversationMemory
            .take(10)
            .toList()
            .asMap()
            .entries
            .map((entry) => '[Memory ${entry.key + 1}] ${_clip(entry.value, 280)}')
            .join('\n');

    return '''
You are an offline tutor for school students.
Course: ${course.name}
Subject: ${subject.name}
Chapter: ${chapter.title}
Language: $tutorLanguage
Chapter Summary: ${_clip(chapter.summary, 220)}

Context:
$contextSection

Conversation Memory:
$memorySection

Rules:
1. Answer directly in simple words.
2. Use short step-by-step reasoning.
3. Add one small example only if needed.
4. Keep response concise unless user asks for detail.
5. Do NOT include tags like <|Question|>, <|Answer|>, <|Roleplay|>.
6. Do NOT roleplay as tutor/student; provide only the final answer.
7. Do NOT repeat the question in your output.

Student Question: $question
Tutor Answer:
''';
  }

  String _clip(String text, int maxChars) {
    final cleaned = text.trim();
    if (cleaned.length <= maxChars) {
      return cleaned;
    }
    return '${cleaned.substring(0, maxChars)}...';
  }
}
