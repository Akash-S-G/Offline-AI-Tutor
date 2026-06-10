import 'package:flutter/material.dart';

import '../objects/renderers/runtime_object_renderer.dart';
import 'bar_chart_state.dart';

class BarChartRenderer extends PlaceholderRuntimeObjectRenderer {
  BarChartState barChartState = const BarChartState.empty();

  void updateBarChartState(BarChartState state) {
    barChartState = state;
  }

  @override
  void render(Canvas canvas, Size size) {
    if (shouldSkipRender()) return;
    _drawFrame(canvas, size);
    final plot = Rect.fromLTWH(32, 18, size.width - 44, size.height - 52);
    _drawAxes(canvas, plot);
    if (barChartState.values.isEmpty) {
      _paintText(
        canvas,
        'No Bars',
        Offset.zero,
        const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        maxWidth: size.width,
        y: size.height / 2 - 10,
        align: TextAlign.center,
      );
      markRendered();
      return;
    }
    final range = barChartState.max - barChartState.min;
    final width = plot.width / barChartState.values.length;
    for (var i = 0; i < barChartState.values.length; i++) {
      final normalized = range == 0
          ? 1.0
          : (barChartState.values[i] - barChartState.min) / range;
      final height = plot.height * normalized.clamp(0, 1).toDouble();
      canvas.drawRect(
        Rect.fromLTWH(
          plot.left + i * width + 4,
          plot.bottom - height,
          (width - 8).clamp(2, width).toDouble(),
          height,
        ),
        Paint()..color = Colors.blue.shade600,
      );
      _paintText(
        canvas,
        barChartState.labels[i],
        Offset(plot.left + i * width, plot.bottom + 4),
        const TextStyle(fontSize: 10, color: Colors.black54),
        maxWidth: width,
        align: TextAlign.center,
      );
    }
    markRendered();
  }

  void _drawFrame(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      Paint()
        ..color = Colors.blue.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawAxes(Canvas canvas, Rect plot) {
    final paint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.5;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, paint);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, paint);
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
    double? y,
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
    painter.paint(canvas, Offset(x, y ?? offset.dy));
  }
}
