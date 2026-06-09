import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'runtime_object_renderer.dart';

class GaugeRenderer extends PlaceholderRuntimeObjectRenderer {
  double lastNormalizedValue = 0;
  String lastValueLabel = '';

  @override
  void update(state) {
    super.update(state);
    lastNormalizedValue = normalize(state.state);
    lastValueLabel = valueLabel(state.state);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (shouldSkipRender()) return;
    final state = latestState!.state;
    final normalized = normalize(state);
    final label = state['label']?.toString() ?? 'Gauge';
    final valueText = valueLabel(state);
    final warningThreshold = _readDouble(state['warningThreshold'], double.nan);
    final warning =
        !warningThreshold.isNaN &&
        _readDouble(state['value'], 0) >= warningThreshold;

    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      Paint()
        ..color = warning ? Colors.deepOrange : Colors.teal.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _paintText(
      canvas,
      label,
      const Offset(14, 10),
      TextStyle(
        color: Colors.grey.shade700,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: size.width - 28,
    );

    final center = Offset(size.width / 2, size.height * 0.73);
    final radius = math.min(size.width * 0.34, size.height * 0.42);
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle * normalized,
      false,
      Paint()
        ..color = warning ? Colors.deepOrange : Colors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    final needleAngle = startAngle + sweepAngle * normalized;
    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * (radius - 8),
      center.dy + math.sin(needleAngle) * (radius - 8),
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = Colors.black87);

    _paintText(
      canvas,
      valueText,
      Offset(0, math.max(34, size.height * 0.34)),
      const TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      maxWidth: size.width,
      align: TextAlign.center,
    );

    lastNormalizedValue = normalized;
    lastValueLabel = valueText;
    markRendered();
  }

  double normalize(Map<String, dynamic> state) {
    final min = _readDouble(state['min'], 0);
    final max = _readDouble(state['max'], 100);
    if (state.containsKey('value')) {
      if (max <= min) return 0;
      final value = _readDouble(state['value'], min);
      return ((value - min) / (max - min)).clamp(0, 1).toDouble();
    }
    final explicit = state['normalizedValue'];
    if (explicit is num) return explicit.toDouble().clamp(0, 1).toDouble();
    return 0;
  }

  String valueLabel(Map<String, dynamic> state) {
    final value = _readDouble(state['value'], 0);
    final precision = _readInt(state['precision'], 0);
    final unit = state['unit']?.toString() ?? '';
    final valueText = value.toStringAsFixed(precision);
    return unit.isEmpty ? valueText : '$valueText $unit';
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);
    final x = align == TextAlign.center
        ? offset.dx + (maxWidth - painter.width) / 2
        : offset.dx;
    painter.paint(canvas, Offset(x, offset.dy));
  }

  double _readDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _readInt(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
