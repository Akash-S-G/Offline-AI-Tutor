/// Very small heuristic-based query classifier for educational content.
class QueryClassification {
  final String subject; // e.g., 'math', 'science', 'language'
  final double complexity; // 0..1
  QueryClassification({required this.subject, required this.complexity});
}

class QueryClassifier {
  QueryClassifier();

  QueryClassification classify(String question) {
    final q = question.toLowerCase();
    String subject = 'general';
    if (RegExp(r"\b(math|algebra|geometry|calculate|solve|equation)\b").hasMatch(q)) {
      subject = 'math';
    } else if (RegExp(r"\b(photosynthesis|biology|cell|organism|chemical|experiment)\b").hasMatch(q)) {
      subject = 'science';
    } else if (RegExp(r"\b(history|geography|date|war|empire)\b").hasMatch(q)) {
      subject = 'social';
    }

    double complexity = 0.2;
    final tokens = q.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    if (tokens > 30) complexity += 0.4;
    if (q.contains('?') && q.split('?').length > 2) complexity += 0.2;
    if (q.contains('explain') || q.contains('derive') || q.contains('prove')) complexity += 0.2;

    if (complexity > 1.0) complexity = 1.0;
    return QueryClassification(subject: subject, complexity: complexity);
  }
}
