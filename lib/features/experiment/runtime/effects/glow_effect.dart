import 'package:flutter/material.dart';
import 'effect.dart';

/// Draws a blur glow circle at the current object position.
/// Reads: effect_x, effect_y, glow_intensity (from visual mapping).
///
/// Params:
///   radius : base glow radius (default: 40)
///   color  : hex color int (default: teal accent)
class GlowEffect implements RuntimeEffect {
  @override
  String get type => 'glow';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final intensity = context.prop('glow_intensity', defaultValue:
        (params['intensity'] as num?)?.toDouble() ?? 0.3);
    if (intensity <= 0.01) return;

    final x = context.get('effect_x', defaultValue: context.size.width / 2);
    final y = context.get('effect_y', defaultValue: context.size.height / 2);
    final baseRadius = (params['radius'] as num?)?.toDouble() ?? 40.0;
    final radius = baseRadius + intensity * 30;

    final paint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: intensity * 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 + intensity * 15);

    context.canvas.drawCircle(Offset(x, y), radius, paint);
  }
}
