import 'dart:math' as math;

import 'package:flutter/material.dart';

class LabDial extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? unit;

  const LabDial({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= min ? min + 1 : max;
    final current = value.clamp(min, safeMax).toDouble();
    final normalized = ((current - min) / (safeMax - min)).clamp(0.0, 1.0);
    return SizedBox(
      width: 112,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              final delta = details.primaryDelta ?? 0;
              onChanged(
                (current + delta * (safeMax - min) / 180)
                    .clamp(min, safeMax)
                    .toDouble(),
              );
            },
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 160),
              child: CustomPaint(
                size: const Size(72, 72),
                painter: _DialPainter(normalized: normalized),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: Text(
                      unit == null
                          ? current.toStringAsFixed(0)
                          : '${current.toStringAsFixed(0)}$unit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          SizedBox(
            height: 24,
            child: Slider(
              value: current,
              min: min,
              max: safeMax,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double normalized;

  const _DialPainter({required this.normalized});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;
    final bg = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bg,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * normalized,
      false,
      fg,
    );
    final angle = math.pi * 0.75 + math.pi * 1.5 * normalized;
    final needleEnd =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius - 7);
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.normalized != normalized;
  }
}
