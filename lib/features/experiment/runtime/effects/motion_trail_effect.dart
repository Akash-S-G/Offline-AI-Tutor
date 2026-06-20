import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'effect.dart';

/// Draws a faded arc trail behind any oscillating or orbiting object.
/// Reads: behavior_angle, pivot_x, pivot_y, radius (from context).
///
/// Params:
///   length  : number of trail frames (default: 20)
///   color   : hex color int (default: blue accent)
class MotionTrailEffect implements RuntimeEffect {
  @override
  String get type => 'motion_trail';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final angle = context.get('behavior_angle');
    final length = context.prop('trail_length', defaultValue:
        (params['length'] as num?)?.toDouble() ?? 0.6);
    final radius = context.get('effect_radius',
        defaultValue: context.size.height * 0.4);
    final pivotX = context.get('pivot_x', defaultValue: context.size.width / 2);
    final pivotY = context.get('pivot_y', defaultValue: context.size.height * 0.18);
    final pivot = Offset(pivotX, pivotY);

    // Draw the sweep arc centred on current angle
    final sweepAngle = length.clamp(0.1, math.pi);
    final paint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.28)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    context.canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: radius),
      math.pi / 2 + angle - sweepAngle / 2,
      sweepAngle,
      false,
      paint,
    );
  }
}
