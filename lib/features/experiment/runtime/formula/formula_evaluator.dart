import 'dart:math' as math;

/// Evaluates simple math expressions from blueprint JSON strings.
///
/// Supported operations: +  -  *  /  ()  sqrt()  abs()  pi  e
/// Variable substitution: any word matching a key in [vars] is replaced.
///
/// Examples:
///   FormulaEvaluator.evaluate('sqrt(9.81 / var_length)', {'var_length': 2.0})
///   → sqrt(4.905) → 2.215
///
///   FormulaEvaluator.evaluate('2 * pi * sqrt(var_length / 9.81)', {'var_length': 1.0})
///   → 2.006
class FormulaEvaluator {
  /// Evaluate [expression] with variable values substituted from [vars].
  /// Returns the computed double, or [defaultValue] if evaluation fails.
  static double evaluate(
    String expression,
    Map<String, double> vars, {
    double defaultValue = 0.0,
  }) {
    try {
      // 1. Substitute known variables longest-first to avoid partial matches
      var expr = expression.trim();
      final sorted = vars.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final key in sorted) {
        expr = expr.replaceAll(key, vars[key].toString());
      }

      // 2. Replace named constants
      expr = expr.replaceAll('pi', math.pi.toString());
      expr = expr.replaceAll('e', math.e.toString());
      expr = expr.replaceAll('g', '9.81'); // gravitational constant shorthand

      // 3. Evaluate
      return _eval(expr);
    } catch (_) {
      return defaultValue;
    }
  }

  // ── Recursive descent parser ───────────────────────────────────────────────

  static double _eval(String expr) {
    final parser = _Parser(expr.replaceAll(' ', ''));
    return parser.parseExpression();
  }
}

class _Parser {
  final String _input;
  int _pos = 0;

  _Parser(this._input);

  double parseExpression() {
    var result = parseTerm();
    while (_pos < _input.length) {
      if (_current == '+') {
        _pos++;
        result += parseTerm();
      } else if (_current == '-') {
        _pos++;
        result -= parseTerm();
      } else {
        break;
      }
    }
    return result;
  }

  double parseTerm() {
    var result = parseFactor();
    while (_pos < _input.length) {
      if (_current == '*') {
        _pos++;
        result *= parseFactor();
      } else if (_current == '/') {
        _pos++;
        final divisor = parseFactor();
        result = divisor != 0 ? result / divisor : 0;
      } else {
        break;
      }
    }
    return result;
  }

  double parseFactor() {
    // Unary minus
    if (_pos < _input.length && _current == '-') {
      _pos++;
      return -parseFactor();
    }

    // Parentheses
    if (_pos < _input.length && _current == '(') {
      _pos++; // consume '('
      final result = parseExpression();
      if (_pos < _input.length && _current == ')') _pos++;
      return result;
    }

    // Functions: sqrt(...), abs(...)
    if (_input.startsWith('sqrt(', _pos)) {
      _pos += 5;
      final arg = parseExpression();
      if (_pos < _input.length && _current == ')') _pos++;
      return math.sqrt(arg < 0 ? 0 : arg);
    }
    if (_input.startsWith('abs(', _pos)) {
      _pos += 4;
      final arg = parseExpression();
      if (_pos < _input.length && _current == ')') _pos++;
      return arg.abs();
    }

    // Number
    final start = _pos;
    if (_pos < _input.length && (_current == '.' || _isDigit(_current))) {
      while (_pos < _input.length && (_isDigit(_current) || _current == '.')) {
        _pos++;
      }
      return double.tryParse(_input.substring(start, _pos)) ?? 0.0;
    }

    return 0.0;
  }

  String get _current => _pos < _input.length ? _input[_pos] : '';
  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}
