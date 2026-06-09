import 'package:math_expressions/math_expressions.dart';

class MathEvaluatorService {
  final Parser _parser = Parser();

  double evaluateExpression(String expression, Map<String, dynamic> variables) {
    final context = ContextModel();
    variables.forEach((key, value) {
      if (value is num) {
        context.bindVariable(Variable(key), Number(value));
      }
    });

    try {
      final expr = _parser.parse(expression);
      // As of math_expressions 3.1.0, expr.evaluate with EvaluationType.REAL is deprecated
      // Use RealEvaluator, but unfortunately the docs for math_expressions 3.1 are not fully standardized
      // Let's just ignore the deprecation since it works, but use standard parser
      return expr.evaluate(EvaluationType.REAL, context);
    } catch (e) {
      // Re-throw or handle as validation exception
      throw Exception('Failed to evaluate expression: $expression, error: $e');
    }
  }
}
