import 'package:flutter/material.dart';
import 'effect.dart';

/// Draws a multi-layered blur glow circle at the current object position.
/// Reads: effect_x, effect_y, glow_radius, glow_intensity (from visual mapping).
///
/// Params:
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
    
    final baseRadius = context.prop('glow_radius', defaultValue: 40.0);
    final colorVal = params['color'] as int?;
    final color = colorVal != null ? Color(colorVal) : Colors.yellowAccent;

    // Outer Diffuse Aura
    final outerPaint = Paint()
      ..color = color.withValues(alpha: intensity * 0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseRadius * 1.5);
    context.canvas.drawCircle(Offset(x, y), baseRadius + intensity * 20, outerPaint);

    // Inner Bright Core
    final innerPaint = Paint()
      ..color = color.withValues(alpha: intensity * 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseRadius * 0.5);
    context.canvas.drawCircle(Offset(x, y), baseRadius * 0.6 + intensity * 10, innerPaint);
  }
}
