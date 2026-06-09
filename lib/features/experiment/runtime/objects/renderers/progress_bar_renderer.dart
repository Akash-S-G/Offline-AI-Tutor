import 'package:flutter/material.dart';

import 'runtime_object_renderer.dart';

class ProgressBarRenderer extends PlaceholderRuntimeObjectRenderer {
  double lastProgress = 0;
  String lastPercentLabel = '0%';

  @override
  void update(state) {
    super.update(state);
    lastProgress = progress(state.state);
    lastPercentLabel = percentLabel(lastProgress);
  }

  @override
  void render(Canvas canvas, Size size) {
    if (shouldSkipRender()) return;
    final state = latestState!.state;
    final label = state['label']?.toString() ?? 'Progress';
    final currentProgress = progress(state);
    final percent = percentLabel(currentProgress);

    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      Paint()
        ..color = Colors.blueGrey.shade200
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

    final barRect = Rect.fromLTWH(14, size.height * 0.48, size.width - 28, 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(9)),
      Paint()..color = Colors.grey.shade200,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          barRect.left,
          barRect.top,
          barRect.width * currentProgress,
          barRect.height,
        ),
        const Radius.circular(9),
      ),
      Paint()..color = Colors.teal,
    );

    _paintText(
      canvas,
      percent,
      Offset(14, size.height * 0.72),
      const TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      maxWidth: size.width - 28,
    );

    lastProgress = currentProgress;
    lastPercentLabel = percent;
    markRendered();
  }

  double progress(Map<String, dynamic> state) {
    final min = _readDouble(state['min'], 0);
    final max = _readDouble(state['max'], 100);
    if (state.containsKey('value')) {
      if (max <= min) return 0;
      final value = _readDouble(state['value'], min);
      return ((value - min) / (max - min)).clamp(0, 1).toDouble();
    }

    final explicitProgress = state['progress'] ?? state['normalizedValue'];
    if (explicitProgress is num) {
      final value = explicitProgress.toDouble();
      return (value > 1 ? value / 100 : value).clamp(0, 1).toDouble();
    }
    return 0;
  }

  String percentLabel(double value) => '${(value * 100).round()}%';

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

  double _readDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
