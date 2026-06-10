import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../objects/renderers/runtime_object_renderer.dart';
import 'vector_visualizer_state.dart';

class VectorVisualizerRenderer extends PlaceholderRuntimeObjectRenderer {
  VectorVisualizerState vectorState = VectorVisualizerState.empty();

  void updateVectorState(VectorVisualizerState state) {
    vectorState = state;
  }

  @override
  void render(Canvas canvas, Size size) {
    if (shouldSkipRender()) return;
    _drawFrame(canvas, size);

    final center = Offset(size.width * 0.5, size.height * 0.58);
    final maxLength = math.min(size.width, size.height) * 0.32;
    final scale = vectorState.magnitude == 0
        ? 0.0
        : maxLength / vectorState.magnitude;
    final end = Offset(
      center.dx + vectorState.x * scale,
      center.dy - vectorState.y * scale,
    );

    final axisPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(18, center.dy),
      Offset(size.width - 18, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, 34),
      Offset(center.dx, size.height - 18),
      axisPaint,
    );
    canvas.drawCircle(center, 4, Paint()..color = Colors.black87);

    final arrowPaint = Paint()
      ..color = Colors.indigo
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, end, arrowPaint);
    _drawArrowHead(canvas, center, end, arrowPaint);

    _paintText(
      canvas,
      'Vector',
      const Offset(12, 8),
      const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      maxWidth: size.width - 24,
    );
    _paintText(
      canvas,
      'mag ${_fmt(vectorState.magnitude)} ${vectorState.unit}',
      Offset(12, size.height - 42),
      const TextStyle(fontSize: 12, color: Colors.black87),
      maxWidth: size.width - 24,
    );
    _paintText(
      canvas,
      'x ${_fmt(vectorState.x)}  y ${_fmt(vectorState.y)}  z ${_fmt(vectorState.z)}',
      Offset(12, size.height - 24),
      const TextStyle(fontSize: 11, color: Colors.black54),
      maxWidth: size.width - 24,
    );
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
        ..color = Colors.indigo.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    if ((end - start).distance < 1) return;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const headLength = 12.0;
    for (final delta in const [math.pi * 0.82, -math.pi * 0.82]) {
      final point = Offset(
        end.dx + math.cos(angle + delta) * headLength,
        end.dy + math.sin(angle + delta) * headLength,
      );
      canvas.drawLine(end, point, paint);
    }
  }

  String _fmt(double value) => value.toStringAsFixed(2);

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
}
