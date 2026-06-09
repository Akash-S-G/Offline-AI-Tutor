import 'package:flutter/material.dart';

import '../objects/renderers/runtime_object_renderer.dart';
import 'line_graph_state.dart';
import 'runtime_graph_point.dart';

class LineGraphRenderer extends PlaceholderRuntimeObjectRenderer {
  LineGraphState graphState = const LineGraphState.empty();
  DateTime? lastGraphRenderTime;

  void updateGraphState(LineGraphState state) {
    graphState = state;
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
      32,
      14,
      (size.width - 46).clamp(1, size.width).toDouble(),
      (size.height - 42).clamp(1, size.height).toDouble(),
    );
    _drawAxes(canvas, plotRect);

    if (graphState.sampleCount == 0) {
      _paintText(
        canvas,
        'No Data',
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
      lastGraphRenderTime = lastRenderTime;
      return;
    }

    if (graphState.sampleCount == 1) {
      final point = _mapPoint(graphState.points.single, plotRect);
      canvas.drawCircle(point, 4, Paint()..color = Colors.teal);
      markRendered();
      lastGraphRenderTime = lastRenderTime;
      return;
    }

    final path = Path();
    final first = _mapPoint(graphState.points.first, plotRect);
    path.moveTo(first.dx, first.dy);
    for (final point in graphState.points.skip(1)) {
      final mapped = _mapPoint(point, plotRect);
      path.lineTo(mapped.dx, mapped.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final last = _mapPoint(graphState.points.last, plotRect);
    canvas.drawCircle(last, 3.5, Paint()..color = Colors.teal.shade700);

    markRendered();
    lastGraphRenderTime = lastRenderTime;
  }

  void _drawAxes(Canvas canvas, Rect plotRect) {
    final axisPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5;
    canvas.drawLine(plotRect.bottomLeft, plotRect.bottomRight, axisPaint);
    canvas.drawLine(plotRect.bottomLeft, plotRect.topLeft, axisPaint);
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = plotRect.top + plotRect.height * i / 4;
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
    }
  }

  Offset _mapPoint(RuntimeGraphPoint point, Rect plotRect) {
    final xRange = graphState.maxX - graphState.minX;
    final yRange = graphState.maxY - graphState.minY;
    final normalizedX = xRange == 0
        ? 0.5
        : (point.x - graphState.minX) / xRange;
    final normalizedY = yRange == 0
        ? 0.5
        : (point.y - graphState.minY) / yRange;
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
