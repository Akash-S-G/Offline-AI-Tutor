import 'package:flutter/material.dart';

import '../objects/renderers/runtime_object_renderer.dart';
import 'spectrum_analyzer_state.dart';

class SpectrumAnalyzerRenderer extends PlaceholderRuntimeObjectRenderer {
  SpectrumAnalyzerState spectrumState = const SpectrumAnalyzerState.empty();

  void updateSpectrumState(SpectrumAnalyzerState state) {
    spectrumState = state;
  }

  @override
  void render(Canvas canvas, Size size) {
    if (shouldSkipRender()) return;
    _drawFrame(canvas, size);
    final plot = Rect.fromLTWH(30, 20, size.width - 42, size.height - 46);
    canvas.drawLine(
      plot.bottomLeft,
      plot.bottomRight,
      Paint()
        ..color = Colors.grey.shade700
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      plot.bottomLeft,
      plot.topLeft,
      Paint()
        ..color = Colors.grey.shade700
        ..strokeWidth = 1.5,
    );
    if (spectrumState.amplitudes.isEmpty) {
      _paintText(
        canvas,
        'No Spectrum',
        Offset.zero,
        const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        maxWidth: size.width,
        y: size.height / 2 - 10,
        align: TextAlign.center,
      );
      markRendered();
      return;
    }
    final maxAmp = spectrumState.amplitudes.reduce((a, b) => a > b ? a : b);
    final barWidth = plot.width / spectrumState.amplitudes.length;
    final paint = Paint()..color = Colors.deepOrange.shade600;
    for (var i = 0; i < spectrumState.amplitudes.length; i++) {
      final height = maxAmp == 0
          ? 0.0
          : plot.height * (spectrumState.amplitudes[i] / maxAmp);
      canvas.drawRect(
        Rect.fromLTWH(
          plot.left + i * barWidth,
          plot.bottom - height,
          (barWidth - 1).clamp(1, barWidth).toDouble(),
          height,
        ),
        paint,
      );
    }
    _paintText(
      canvas,
      'Peak ${spectrumState.peakFrequency.toStringAsFixed(1)} Hz',
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
        ..color = Colors.deepOrange.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
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
