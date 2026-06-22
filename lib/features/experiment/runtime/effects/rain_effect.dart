import 'package:flutter/material.dart';
import 'effect.dart';

/// Falling water droplets from the top — used by Water Cycle.
/// Reads: dropCount and dropSpeed from properties
class RainEffect implements RuntimeEffect {
  @override
  String get type => 'rain';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final dropCount = context.prop('dropCount', defaultValue: 0.0);
    final dropSpeed = context.prop('dropSpeed', defaultValue: 10.0);
    
    if (dropCount <= 0.01) return;

    final count = dropCount.toInt().clamp(5, 100);
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final x = (i * 23.7) % context.size.width;
      final y = (context.time * dropSpeed * 20 + i * 43) % context.size.height;
      context.canvas.drawLine(
        Offset(x, y),
        Offset(x - 3, y + 14),
        paint,
      );
    }
  }
}
