/// Lightweight educational confidence evaluator.
class ConfidenceScore {
  final double score; // 0..1
  final List<String> reasons;
  ConfidenceScore(this.score, [this.reasons = const []]);
}

class ConfidenceEvaluator {
  ConfidenceEvaluator({
    this.minAcceptable = 0.6,
  });

  final double minAcceptable;

  /// Evaluate a partial or final assistant text and return a confidence score.
  ConfidenceScore evaluate(String assistantText) {
    final text = assistantText.trim();
    final reasons = <String>[];

    if (text.isEmpty) {
      reasons.add('empty_response');
    }

    // repeated phrase heuristic
    final repeats = _detectRepetition(text);
    if (repeats) {
      reasons.add('repetition');
    }

    // trailing unfinished sentence
    if (_looksIncomplete(text)) {
      reasons.add('incomplete');
    }

    // simple length heuristic
    final len = text.length;
    double base = 0.5;
    if (len > 200) base += 0.3;
    if (len > 400) base += 0.1;

    if (!text.contains('?') && text.split(RegExp(r'\.|!|\?')).length <= 1) {
      reasons.add('short_exposition');
      base -= 0.1;
    }

    var score = base.clamp(0.0, 1.0);
    if (repeats) score -= 0.25;
    if (_hasFollowupQuestion(text)) {
      reasons.add('self_followup');
      score -= 0.15;
    }

    score = score.clamp(0.0, 1.0);
    return ConfidenceScore(score, reasons);
  }

  bool shouldEscalate(String assistantText) {
    final c = evaluate(assistantText);
    return c.score < minAcceptable;
  }

  bool _detectRepetition(String text) {
    final tokens = text.split(RegExp(r'\s+'));
    if (tokens.length < 4) return false;

    // Same token repeated several times in a row.
    for (var i = 0; i + 2 < tokens.length; i++) {
      final token = tokens[i].toLowerCase();
      if (token.isNotEmpty &&
          token == tokens[i + 1].toLowerCase() &&
          token == tokens[i + 2].toLowerCase()) {
        return true;
      }
    }

    final window = 6;
    if (tokens.length < window * 2) {
      return false;
    }
    for (var i = 0; i + window * 2 <= tokens.length; i++) {
      final a = tokens.sublist(i, i + window).join(' ');
      for (var j = i + window; j + window <= tokens.length; j++) {
        final b = tokens.sublist(j, j + window).join(' ');
        if (a == b) return true;
      }
    }
    return false;
  }

  bool _looksIncomplete(String text) {
    if (text.isEmpty) return true;
    if (text.trim().endsWith(':')) return true;
    if (RegExp(r"\b(to be continued|to continue|more to follow)\b", caseSensitive: false).hasMatch(text)) return true;
    final sentences = text.split(RegExp(r'[.!?]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return sentences.isEmpty || sentences.last.length < 20;
  }

  bool _hasFollowupQuestion(String text) {
    return RegExp(r"(Do you want|Would you like|Should I|Shall I|Any questions)", caseSensitive: false).hasMatch(text);
  }
}
