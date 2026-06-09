import 'package:flutter/material.dart';

import 'runtime_object_renderer.dart';

class NumericDisplayRenderer extends PlaceholderRuntimeObjectRenderer {
  String lastLabel = '';
  String lastFormattedValue = '';

  @override
  void update(state) {
    super.update(state);
    lastLabel = state.state['label']?.toString() ?? 'Value';
    lastFormattedValue = formatValue(state.state);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (shouldSkipRender()) return;
    final state = latestState!.state;
    final label = state['label']?.toString() ?? lastLabel;
    final value = formatValue(state);

    final background = Paint()..color = Colors.white;
    final border = Paint()
      ..color = Colors.teal.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      background,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      border,
    );

    _paintText(
      canvas,
      label,
      const Offset(14, 12),
      TextStyle(
        color: Colors.grey.shade700,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      maxWidth: size.width - 28,
    );
    _paintText(
      canvas,
      value,
      Offset(14, size.height * 0.43),
      const TextStyle(
        color: Colors.black87,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      maxWidth: size.width - 28,
    );

    lastLabel = label;
    lastFormattedValue = value;
    markRendered();
  }

  String formatValue(Map<String, dynamic> state) {
    final formatted = state['formattedValue']?.toString();
    if (formatted != null && formatted.isNotEmpty) {
      final unit = state['unit']?.toString() ?? '';
      return unit.isEmpty ? formatted : '$formatted $unit';
    }

    final value = state['value'];
    final precision = _readInt(state['precision'], 1);
    final unit = state['unit']?.toString() ?? '';
    final valueText = value is num
        ? value.toDouble().toStringAsFixed(precision)
        : value?.toString() ?? '';
    return unit.isEmpty ? valueText : '$valueText $unit';
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
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  int _readInt(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
