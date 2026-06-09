import 'package:flutter/material.dart';

import '../objects/renderers/runtime_object_renderer.dart';
import 'runtime_scatter_point.dart';
import 'scatter_plot_state.dart';

class ScatterPlotRenderer extends PlaceholderRuntimeObjectRenderer {
  ScatterPlotState scatterState = ScatterPlotState.empty();
  DateTime? lastScatterRenderTime;

  void updateScatterState(ScatterPlotState state) {
    scatterState = state;
  }

  @override
  void render(Canvas canvas, Size size) {
    if (shouldSkipRender()) return;

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

    final plotRect = Rect.fromLTWH(
      34,
      14,
      (size.width - 48).clamp(1, size.width).toDouble(),
      (size.height - 44).clamp(1, size.height).toDouble(),
    );
    _drawAxes(canvas, plotRect);

    if (scatterState.pointCount == 0) {
      _paintText(
        canvas,
        'No Points',
        Offset.zero,
        const TextStyle(
          color: Colors.black54,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        maxWidth: size.width,
        y: size.height / 2 - 10,
        align: TextAlign.center,
      );
      markRendered();
      lastScatterRenderTime = lastRenderTime;
      return;
    }

    final pointPaint = Paint()..color = Colors.deepPurple.shade600;
    for (final point in scatterState.points) {
      canvas.drawCircle(_mapPoint(point, plotRect), 3.5, pointPaint);
    }

    _paintText(
      canvas,
      '${scatterState.pointCount} pts',
      const Offset(8, 0),
      const TextStyle(color: Colors.black54, fontSize: 11),
      maxWidth: size.width - 16,
      y: size.height - 18,
    );

    markRendered();
    lastScatterRenderTime = lastRenderTime;
  }

  void _drawAxes(Canvas canvas, Rect plotRect) {
    final axisPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.5;
    canvas.drawLine(plotRect.bottomLeft, plotRect.bottomRight, axisPaint);
    canvas.drawLine(plotRect.bottomLeft, plotRect.topLeft, axisPaint);

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = plotRect.top + plotRect.height * i / 4;
      final x = plotRect.left + plotRect.width * i / 4;
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
      canvas.drawLine(
        Offset(x, plotRect.top),
        Offset(x, plotRect.bottom),
        gridPaint,
      );
    }
  }

  Offset _mapPoint(RuntimeScatterPoint point, Rect plotRect) {
    final xRange = scatterState.maxX - scatterState.minX;
    final yRange = scatterState.maxY - scatterState.minY;
    final normalizedX = xRange == 0
        ? 0.5
        : (point.x - scatterState.minX) / xRange;
    final normalizedY = yRange == 0
        ? 0.5
        : (point.y - scatterState.minY) / yRange;
    return Offset(
      plotRect.left + plotRect.width * normalizedX.clamp(0, 1).toDouble(),
      plotRect.bottom - plotRect.height * normalizedY.clamp(0, 1).toDouble(),
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
    required double y,
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
    painter.paint(canvas, Offset(x, y));
  }
}
