import 'package:flutter/material.dart';

import 'runtime_object_renderer.dart';

class TextDisplayRenderer extends PlaceholderRuntimeObjectRenderer {
  String lastLabel = '';
  String lastRenderedText = '';

  @override
  void update(state) {
    super.update(state);
    lastLabel = state.state['label']?.toString() ?? 'Status';
    lastRenderedText = resolveText(state.state);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (shouldSkipRender()) return;
    final state = latestState!.state;
    final label = state['label']?.toString() ?? lastLabel;
    final text = resolveText(state);

    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      Paint()..color = Colors.indigo.shade50,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      Paint()
        ..color = Colors.indigo.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _paintText(
      canvas,
      label,
      const Offset(14, 12),
      TextStyle(
        color: Colors.indigo.shade700,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: size.width - 28,
    );
    _paintText(
      canvas,
      text,
      Offset(14, size.height * 0.43),
      const TextStyle(
        color: Colors.black87,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      maxWidth: size.width - 28,
    );

    lastLabel = label;
    lastRenderedText = text;
    markRendered();
  }

  String resolveText(Map<String, dynamic> state) {
    final formatted = state['formattedText']?.toString();
    if (formatted != null && formatted.isNotEmpty) return formatted;
    final text = state['text']?.toString();
    if (text != null && text.isNotEmpty) return text;
    return state['value']?.toString() ?? '';
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }
}
