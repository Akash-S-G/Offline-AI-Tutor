import 'package:flutter/material.dart';
import 'effect.dart';

/// Expanding concentric rings from a point — used by Water Cycle, Sound, Wave.
/// Reads: effect_x, effect_y, ripple_intensity.
class RippleEffect implements RuntimeEffect {
  @override
  String get type => 'ripple';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final intensity = context.prop('ripple_intensity', defaultValue: 0.5);
    if (intensity <= 0.01) return;

    final x = context.get('effect_x', defaultValue: context.size.width / 2);
    final y = context.get('effect_y', defaultValue: context.size.height * 0.75);

    final ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final progress = (context.time * 0.5 + i / ringCount) % 1.0;
      final radius = 20 + progress * 80 * intensity;
      final alpha = (1.0 - progress) * intensity * 0.6;
      if (alpha <= 0) continue;

      final paint = Paint()
        ..color = Colors.lightBlueAccent.withValues(alpha: alpha)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      context.canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
}
