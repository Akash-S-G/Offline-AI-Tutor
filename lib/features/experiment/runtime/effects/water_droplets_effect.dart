import 'package:flutter/material.dart';
import 'dart:math';
import 'effect.dart';

/// Generic falling/pooling droplets effect.
/// Used for watering plants, rain, or hydrology.
/// 
/// Properties:
///   droplet_frequency: how many droplets (0-100)
///   droplet_speed: speed multiplier
class WaterDropletsEffect implements RuntimeEffect {
  @override
  String get type => 'water_droplets';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final frequency = context.prop('droplet_frequency', defaultValue: 0.0);
    final speed = context.prop('droplet_speed', defaultValue: 1.0);

    if (frequency <= 0.01) return;

    final count = frequency.toInt().clamp(1, 40);
    final paint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Draw droplets near the left side (simulating a watering can)
    for (int i = 0; i < count; i++) {
      // Use pseudo-random offsets based on index
      final x = (i * 13.7) % (context.size.width * 0.4); 
      final y = (context.time * 150 * speed + i * 29) % context.size.height;
      
      context.canvas.drawCircle(Offset(x, y), 3.0, paint);
      
      // Draw a trailing tail
      final tailPaint = Paint()
        ..color = Colors.lightBlue.withValues(alpha: 0.3)
        ..strokeWidth = 2.0;
      context.canvas.drawLine(Offset(x, y), Offset(x, y - 8), tailPaint);
    }
  }
}
