import '../../../config/app_environment.dart';
import 'confidence_evaluator.dart';

class EscalationDecision {
  const EscalationDecision({
    required this.shouldEscalate,
    required this.reason,
    required this.confidence,
  });

  final bool shouldEscalate;
  final String reason;
  final double confidence;
}

class EscalationCoordinator {
  EscalationCoordinator({this.threshold = 0.6});

  final double threshold;

  EscalationDecision evaluate({
    required String question,
    required String partialAnswer,
    ConfidenceScore? score,
  }) {
    final result = score ?? ConfidenceEvaluator().evaluate(partialAnswer);
    final shouldEscalate = result.score < threshold || question.length > 180;
    final reason = shouldEscalate
        ? 'low_confidence_or_complex_query'
        : 'local_response_is_sufficient';
    
    AppEnvironment.log(
      'ROUTING',
      'Escalation decision: shouldEscalate=$shouldEscalate, reason=$reason, confidence=${result.score.toStringAsFixed(2)}',
    );
    
    return EscalationDecision(
      shouldEscalate: shouldEscalate,
      reason: reason,
      confidence: result.score,
    );
  }
}
