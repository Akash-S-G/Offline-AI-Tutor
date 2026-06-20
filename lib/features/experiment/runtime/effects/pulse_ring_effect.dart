import 'package:flutter/material.dart';
import 'effect.dart';

/// BPM-driven expanding rings from screen center — used by Heart Rate.
/// Reads: pulse_intensity (from PulseBehavior output or visual mapping).
class PulseRingEffect implements RuntimeEffect {
  @override
  String get type => 'pulse_ring';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final intensity = context.prop('pulse_intensity',
        defaultValue: context.get('pulse_intensity', defaultValue: 0.0));
    if (intensity <= 0.01) return;

    final x = context.get('effect_x', defaultValue: context.size.width / 2);
    final y = context.get('effect_y', defaultValue: context.size.height / 2);

    for (int i = 0; i < 3; i++) {
      final offset = i / 3.0;
      final progress = (context.time * (context.get('var_heart_rate', defaultValue: 60) / 60) + offset) % 1.0;
      final radius = 40 + progress * 120;
      final alpha = (1.0 - progress) * intensity;
      if (alpha <= 0) continue;

      final paint = Paint()
        ..color = Colors.redAccent.withValues(alpha: alpha)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      context.canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
}
