import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'effect.dart';

/// Animated dots flowing along a horizontal wire path — used by Circuit.
/// Reads: flow_progress, flow_speed (from FlowBehavior outputs).
///
/// Params:
///   particle_count : default 20
///   color          : hex int (default: yellow accent)
class CurrentFlowEffect implements RuntimeEffect {
  @override
  String get type => 'current_flow';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final flowSpeed = context.get('flow_speed', defaultValue: 0.0);
    if (flowSpeed <= 0.01) return;

    final count = (params['particle_count'] as num?)?.toInt() ?? 20;
    final paint = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final wireY = context.size.height * 0.5;
    final startX = context.size.width * 0.1;
    final endX = context.size.width * 0.9;

    for (int i = 0; i < count; i++) {
      final phase = (context.time * flowSpeed * 0.3 + i / count) % 1.0;
      final x = startX + (endX - startX) * phase;
      final y = wireY + math.sin(phase * math.pi * 4) * 12;
      context.canvas.drawCircle(Offset(x, y), 5, paint);
    }
  }
}
