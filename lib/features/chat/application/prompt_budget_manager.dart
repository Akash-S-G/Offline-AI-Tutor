class PromptBudgetManager {
  const PromptBudgetManager({
    this.maxPromptChars = 3900,
    this.systemChars = 500,
    this.curriculumChars = 220,
    this.summaryChars = 500,
    this.historyChars = 700,
    this.ragChars = 2600,
    this.questionChars = 220,
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

  String hardCapPrompt(String prompt) => clip(prompt, maxPromptChars);

  int estimateTokens(String text) => (text.length / 4).ceil();
}
