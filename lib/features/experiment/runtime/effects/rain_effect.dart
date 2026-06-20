import 'package:flutter/material.dart';
import 'effect.dart';

/// Falling water droplets from the top — used by Water Cycle.
/// Reads: rain_intensity (from visual mapping on var_humidity).
class RainEffect implements RuntimeEffect {
  @override
  String get type => 'rain';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final intensity = context.prop('rain_intensity',
        defaultValue: context.get('rain_intensity', defaultValue: 0.0));
    if (intensity <= 0.01) return;

    final count = (intensity * 80).toInt().clamp(5, 80);
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final x = (i * 17.3) % context.size.width;
      final y = (context.time * 280 + i * 43) % context.size.height;
      context.canvas.drawLine(
        Offset(x, y),
        Offset(x - 3, y + 14),
        paint,
      );
    }
  }
}
