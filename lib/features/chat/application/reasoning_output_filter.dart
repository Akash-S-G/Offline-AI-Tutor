class ReasoningOutputFilter {
  final StringBuffer _buffer = StringBuffer();

  String push(String chunk) {
    if (chunk.isEmpty) {
      return '';
    }

    _buffer.write(chunk);
    final cleaned = stripComplete(_buffer.toString());

    if (_hasOpenReasoningTag(cleaned)) {
      final openIndex = _firstOpenReasoningTag(cleaned);
      final safe = cleaned.substring(0, openIndex);
      _buffer
        ..clear()
        ..write(cleaned.substring(openIndex));
      return safe;
    }

    _buffer.clear();
    return cleaned;
  }

  String flush() {
    final cleaned = stripComplete(_buffer.toString());
    _buffer.clear();
    return cleaned;
  }

  static String stripComplete(String text) {
    var output = text;
    for (final tag in const <String>['think', 'reasoning', 'analysis']) {
      output = output.replaceAll(
        RegExp('<$tag[^>]*>[\\s\\S]*?</$tag>', caseSensitive: false),
        '',
      );
    }
    return output;
  }

  bool _hasOpenReasoningTag(String text) {
    final open = _firstOpenReasoningTag(text);
    if (open < 0) {
      return false;
    }
    final tail = text.substring(open).toLowerCase();
    return !tail.contains('</think>') &&
        !tail.contains('</reasoning>') &&
        !tail.contains('</analysis>');
  }

  int _firstOpenReasoningTag(String text) {
    final match = RegExp(
      r'<(think|reasoning|analysis)\b[^>]*>',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.start ?? -1;
  }
}
