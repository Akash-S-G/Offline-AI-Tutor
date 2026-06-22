import 'dart:math';
import 'package:flutter/material.dart';
import 'effect.dart';

class WaveMotionEffect implements RuntimeEffect {
  @override
  String get type => 'wave_motion';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final amplitude = params['amplitude']?.toDouble() ?? 4.0;
    final speed = params['speed']?.toDouble() ?? 0.3;

    final paintDark = Paint()
      ..color = Colors.blue.shade700.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
      
    final pathDark = Path();
    pathDark.moveTo(0, context.size.height);
    pathDark.lineTo(0, context.size.height * 0.5);

    for (double i = 0; i <= context.size.width; i += 5) {
      final xPhase = (i / context.size.width) * pi * 3; 
      final y = context.size.height * 0.55 + sin(xPhase - (context.time * speed * pi * 0.8)) * (amplitude * 1.5);
      pathDark.lineTo(i, y);
    }

    pathDark.lineTo(context.size.width, context.size.height);
    pathDark.close();
    
    context.canvas.drawPath(pathDark, paintDark);

    final paint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, context.size.height);
    path.lineTo(0, context.size.height * 0.5); 

    for (double i = 0; i <= context.size.width; i += 5) {
      final xPhase = (i / context.size.width) * pi * 4; 
      final y = context.size.height * 0.5 + sin(xPhase + (context.time * speed * pi)) * amplitude;
      path.lineTo(i, y);
    }

    path.lineTo(context.size.width, context.size.height);
    path.close();

    context.canvas.drawPath(path, paint);
  }
}
