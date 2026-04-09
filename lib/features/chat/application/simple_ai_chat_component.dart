class SimpleAiChatComponent {
  const SimpleAiChatComponent();

  static final RegExp _greetingPattern = RegExp(
    r'^(hi|hello|hey|hii+|good\s*(morning|afternoon|evening)|how are you)\b',
    caseSensitive: false,
  );

  String? localFastReply({required String question}) {
    final q = question.trim();
    if (q.isEmpty) {
      return null;
    }

    final normalized = q.toLowerCase();
    if (_greetingPattern.hasMatch(normalized)) {
      if (normalized.contains('how are you')) {
        return 'I am good and ready to help you. Ask me a chapter question and I will explain it step by step.';
      }
      return 'Hi. I am ready to help with your chapter. Ask your question and I will answer clearly.';
    }

    return null;
  }

  String? localMathReply({required String question}) {
    final q = question.trim().toLowerCase();
    if (q.isEmpty) {
      return null;
    }

    final cleaned = q
        .replaceAll('what is', '')
        .replaceAll('solve', '')
        .replaceAll('calculate', '')
        .replaceAll('evaluate', '')
        .replaceAll('find', '')
        .replaceAll('please', '')
        .trim();

    final arithmeticText = cleaned
        .replaceAll('plus', '+')
        .replaceAll('minus', '-')
        .replaceAll('times', '*')
        .replaceAll('multiplied by', '*')
        .replaceAll('divide by', '/')
        .replaceAll('divided by', '/');

    final simpleBinary = RegExp(r'^(-?\d+(?:\.\d+)?)\s*([+\-*/])\s*(-?\d+(?:\.\d+)?)$');
    final match = simpleBinary.firstMatch(arithmeticText.replaceAll('=', '').trim());
    if (match != null) {
      final left = double.tryParse(match.group(1) ?? '');
      final op = match.group(2);
      final right = double.tryParse(match.group(3) ?? '');
      if (left == null || right == null || op == null) {
        return null;
      }

      final result = switch (op) {
        '+' => left + right,
        '-' => left - right,
        '*' => left * right,
        '/' => right == 0 ? double.nan : left / right,
        _ => double.nan,
      };
      if (result.isNaN) {
        return 'That expression cannot be solved as written.';
      }

      final formatted = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(2);
      return 'The answer is $formatted.';
    }

    final linearEquation = RegExp(r'^(?:(-?\d+)\s*)?x\s*([+\-])\s*(\d+)\s*=\s*(-?\d+)$');
    final linearMatch = linearEquation.firstMatch(arithmeticText.replaceAll(' ', ''));
    if (linearMatch != null) {
      final coefficient = int.tryParse(linearMatch.group(1) ?? '1') ?? 1;
      final sign = linearMatch.group(2) ?? '+';
      final constant = int.tryParse(linearMatch.group(3) ?? '0') ?? 0;
      final total = int.tryParse(linearMatch.group(4) ?? '0') ?? 0;
      final x = sign == '+'
          ? (total - constant) / coefficient
          : (total + constant) / coefficient;
      if (x.isNaN || x.isInfinite) {
        return null;
      }
      final formatted = x % 1 == 0 ? x.toInt().toString() : x.toStringAsFixed(2);
      return 'x = $formatted.';
    }

    final simpleEquation = RegExp(r'^(?:(-?\d+)\s*)?x\s*=\s*(-?\d+)$');
    final eqMatch = simpleEquation.firstMatch(arithmeticText.replaceAll(' ', ''));
    if (eqMatch != null) {
      final rhs = eqMatch.group(2) ?? '';
      return 'x = $rhs.';
    }

    return null;
  }

  String buildPrompt({required String question}) {
    final q = question.trim();
    if (q.isEmpty) {
      return '';
    }

    return '''
You are an offline school tutor in answer mode.
Reply to only this one user query.
Return one short answer only.
Do not repeat the question.
Do not output labels like Student, Tutor, User query, Direct reply, Question, Answer, or Follow-up questions.
Do not output control tags like <|...|>.
Keep the answer short, direct, and relevant.

User query: $q

Answer:
''';
  }

  String buildRecoveryPrompt({required String question}) {
    final q = question.trim();
    if (q.isEmpty) {
      return '';
    }

    return '''
You are an offline school tutor.
    The previous output repeated or answered in the wrong format.
    Return one short answer only.
    No headings, no labels, no question repetition, no extra examples.
    Keep the answer short and direct.

User query: $q

    Answer:
''';
  }
}
