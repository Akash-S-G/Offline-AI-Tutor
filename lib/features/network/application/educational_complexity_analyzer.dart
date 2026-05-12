class EducationalComplexityAnalysis {
  const EducationalComplexityAnalysis({
    required this.score,
    required this.subject,
    required this.tags,
  });

  final double score;
  final String subject;
  final List<String> tags;
}

class EducationalComplexityAnalyzer {
  const EducationalComplexityAnalyzer();

  EducationalComplexityAnalysis analyze(String question) {
    final lower = question.toLowerCase();
    final tokens = lower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).length;

    var score = 0.2;
    if (tokens > 25) score += 0.25;
    if (lower.contains('explain') || lower.contains('why') || lower.contains('derive') || lower.contains('prove')) {
      score += 0.25;
    }
    if (lower.contains('step') || lower.contains('show work') || lower.contains('compare')) {
      score += 0.15;
    }
    if (lower.contains('?') && lower.split('?').length > 2) score += 0.15;

    final subject = _subjectFor(lower);
    final tags = <String>[];
    if (subject != 'general') tags.add(subject);
    if (score >= 0.7) tags.add('complex');
    if (score < 0.35) tags.add('simple');

    return EducationalComplexityAnalysis(
      score: score.clamp(0.0, 1.0),
      subject: subject,
      tags: tags,
    );
  }

  String _subjectFor(String text) {
    if (RegExp(r'\b(math|equation|algebra|geometry|calculate)\b').hasMatch(text)) return 'math';
    if (RegExp(r'\b(science|biology|chemistry|physics|experiment)\b').hasMatch(text)) return 'science';
    if (RegExp(r'\b(history|geography|social|civics)\b').hasMatch(text)) return 'social';
    if (RegExp(r'\b(language|grammar|reading|write)\b').hasMatch(text)) return 'language';
    return 'general';
  }
}
