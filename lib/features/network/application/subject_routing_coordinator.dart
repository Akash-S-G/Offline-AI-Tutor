import 'educational_complexity_analyzer.dart';

class SubjectRoutingCoordinator {
  const SubjectRoutingCoordinator();

  String preferredRouteFor(String question) {
    final analysis = const EducationalComplexityAnalyzer().analyze(question);
    if (analysis.subject == 'general') return analysis.score > 0.65 ? 'backend' : 'local';
    if (analysis.score > 0.7) return 'backend';
    return 'local';
  }
}
