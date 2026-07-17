class PromptBudgetManager {
  const PromptBudgetManager({
    this.maxPromptChars = 1500,
    this.systemChars = 400,
    this.curriculumChars = 150,
    this.summaryChars = 200,
    this.historyChars = 150,
    this.ragChars = 500,
    this.questionChars = 150,
  });

  final int maxPromptChars;
  final int systemChars;
  final int curriculumChars;
  final int summaryChars;
  final int historyChars;
  final int ragChars;
  final int questionChars;

  String clip(String text, int maxChars) {
    final cleaned = text.trim();
    if (cleaned.length <= maxChars) {
      return cleaned;
    }
    return '${cleaned.substring(0, maxChars).trimRight()}...';
  }

  List<String> fitLines(List<String> lines, int maxChars) {
    var used = 0;
    final output = <String>[];

    for (final line in lines) {
      final clean = line.trim();
      if (clean.isEmpty) {
        continue;
      }
      final nextLength = clean.length + (output.isEmpty ? 0 : 1);
      if (used + nextLength > maxChars) {
        if (output.isEmpty) {
          output.add(clip(clean, maxChars));
        }
        break;
      }
      output.add(clean);
      used += nextLength;
    }

    return output;
  }

  String hardCapPrompt(String prompt) {
    if (prompt.length <= maxPromptChars) {
      return prompt;
    }

    final questionIndex = prompt.lastIndexOf('Student question:');
    if (questionIndex != -1) {
      final questionPart = prompt.substring(questionIndex);
      final remainingBudget = maxPromptChars - questionPart.length;

      if (remainingBudget > 100) {
        final headPart = prompt.substring(0, questionIndex);
        final clippedHead = clip(headPart, remainingBudget);
        return '$clippedHead\n\n$questionPart';
      }
    }

    return clip(prompt, maxPromptChars);
  }

  int estimateTokens(String text) => (text.length / 4).ceil();
}
