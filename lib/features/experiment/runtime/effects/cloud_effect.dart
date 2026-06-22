import 'dart:math';
import 'package:flutter/material.dart';
import 'effect.dart';

class CloudEffect implements RuntimeEffect {
  @override
  String get type => 'cloud';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final opacity = context.prop('opacity', defaultValue: 0.0);
    final scale = context.prop('scale', defaultValue: 0.0);

    if (opacity <= 0.01 || scale <= 0.01) return;

    final normalizedOpacity = (opacity / 100.0).clamp(0.0, 1.0);
    final normalizedScale = 0.5 + (scale / 100.0) * 1.5;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: normalizedOpacity * 0.9)
      ..style = PaintingStyle.fill;

    // Draw stylized cloud using overlapping circles in the upper area
    final center = Offset(context.size.width / 2, context.size.height * 0.2);
    final baseRadius = min(context.size.width, context.size.height) * 0.15 * normalizedScale;

    context.canvas.drawCircle(center, baseRadius, paint);
    context.canvas.drawCircle(Offset(center.dx - baseRadius * 1.2, center.dy + baseRadius * 0.2), baseRadius * 0.8, paint);
    context.canvas.drawCircle(Offset(center.dx + baseRadius * 1.2, center.dy + baseRadius * 0.2), baseRadius * 0.8, paint);
    context.canvas.drawCircle(Offset(center.dx - baseRadius * 0.6, center.dy - baseRadius * 0.5), baseRadius * 0.9, paint);
    context.canvas.drawCircle(Offset(center.dx + baseRadius * 0.6, center.dy - baseRadius * 0.5), baseRadius * 0.9, paint);
  }
}
