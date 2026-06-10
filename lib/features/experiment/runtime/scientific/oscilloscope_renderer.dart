import 'package:flutter/material.dart';

import '../objects/renderers/runtime_object_renderer.dart';
import 'oscilloscope_state.dart';

class OscilloscopeRenderer extends PlaceholderRuntimeObjectRenderer {
  OscilloscopeState oscilloscopeState = const OscilloscopeState.empty();

  void updateOscilloscopeState(OscilloscopeState state) {
    oscilloscopeState = state;
  }

  @override
  void render(Canvas canvas, Size size) {
    if (shouldSkipRender()) return;
    _drawFrame(canvas, size);
    final plot = Rect.fromLTWH(26, 22, size.width - 38, size.height - 46);
    _drawGrid(canvas, plot);
    if (oscilloscopeState.samples.isEmpty) {
      _paintText(
        canvas,
        'No Waveform',
        Offset.zero,
        const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        maxWidth: size.width,
        y: size.height / 2 - 10,
        align: TextAlign.center,
      );
      markRendered();
      return;
    }
    final path = Path();
    for (var i = 0; i < oscilloscopeState.samples.length; i++) {
      final x =
          plot.left +
          plot.width *
              (oscilloscopeState.samples.length == 1
                  ? 0
                  : i / (oscilloscopeState.samples.length - 1));
      final normalized =
          (oscilloscopeState.samples[i] / oscilloscopeState.amplitudeScale)
              .clamp(-1, 1)
              .toDouble();
      final y = plot.center.dy - normalized * plot.height / 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.green.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _paintText(
      canvas,
      '${oscilloscopeState.sampleCount} samples',
      Offset(10, size.height - 20),
      const TextStyle(fontSize: 11, color: Colors.black54),
      maxWidth: size.width - 20,
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
        ..color = Colors.green.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawGrid(Canvas canvas, Rect plot) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    final centerPaint = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 1.5;
    for (var i = 0; i <= 4; i++) {
      final x = plot.left + plot.width * i / 4;
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), gridPaint);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }
    canvas.drawLine(plot.centerLeft, plot.centerRight, centerPaint);
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
