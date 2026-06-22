import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'effect.dart';

/// Renders a generic vascular flow effect (red and blue particles moving along a path).
/// 
/// Properties:
///   flow_speed: speed multiplier
class BloodFlowEffect implements RuntimeEffect {
  @override
  String get type => 'blood_flow';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final speed = context.prop('flow_speed', defaultValue: 1.0);
    
    if (speed <= 0.01) return;

    final paintRed = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
      
    final paintBlue = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    final cellCount = 20;
    
    // Draw cells moving in a loop (elliptical orbit simulating circulation)
    for (int i = 0; i < cellCount; i++) {
      // Offset time by index to spread cells out
      final t = (context.time * speed * 0.5 + (i / cellCount)) % 1.0;
      
      // Ellipse path
      final cx = context.size.width / 2;
      final cy = context.size.height / 2;
      final rx = context.size.width * 0.4;
      final ry = context.size.height * 0.3;
      
      // Calculate position
      final angle = t * math.pi * 2;
      final x = cx + math.cos(angle) * rx;
      final y = cy + math.sin(angle) * ry;
      
      // Cells moving left to right (top half) are red (oxygenated), right to left (bottom half) are blue (deoxygenated)
      final isOxygenated = math.sin(angle) < 0;
      
      // Slight jitter
      final jitterX = math.sin(i * 12.3) * 5;
      final jitterY = math.cos(i * 8.7) * 5;

      context.canvas.drawCircle(Offset(x + jitterX, y + jitterY), 4.0, isOxygenated ? paintRed : paintBlue);
    }
  }
}
