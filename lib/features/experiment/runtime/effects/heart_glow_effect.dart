import 'package:flutter/material.dart';
import 'effect.dart';

/// Renders a generic glowing anatomical shape (like a heart) that pulses based on intensity.
/// 
/// Properties:
///   pulse_intensity: The current pulse scale/intensity (0.0 - 1.0+)
class HeartGlowEffect implements RuntimeEffect {
  @override
  String get type => 'heart_glow';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final intensity = context.prop('pulse_intensity', defaultValue: 0.0);
    
    // Scale heart size based on pulse intensity
    final scale = 1.0 + (intensity * 0.2);
    
    final paint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
      
    final glowPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.4 * intensity)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Center of the screen
    final cx = context.size.width / 2;
    final cy = context.size.height / 2;
    
    // Base size
    final size = 40.0 * scale;

    context.canvas.save();
    context.canvas.translate(cx, cy);
    
    // Draw glow
    context.canvas.drawCircle(Offset.zero, size * 1.5, glowPaint);
    
    // Draw abstract heart shape (two intersecting circles and a triangle base)
    final path = Path();
    path.moveTo(0, size * 0.8); // bottom tip
    path.cubicTo(-size, 0, -size * 1.5, -size, -size * 0.5, -size * 1.2);
    path.cubicTo(-size * 0.1, -size * 1.3, 0, -size * 0.5, 0, -size * 0.5);
    path.cubicTo(0, -size * 0.5, size * 0.1, -size * 1.3, size * 0.5, -size * 1.2);
    path.cubicTo(size * 1.5, -size, size, 0, 0, size * 0.8);
    
    context.canvas.drawPath(path, paint);
    
    context.canvas.restore();
  }
}
