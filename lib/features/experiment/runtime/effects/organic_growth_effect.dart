import 'package:flutter/material.dart';
import 'dart:math';
import 'effect.dart';

/// Renders generic node-based growth elements like leaves or biological cells.
/// 
/// Properties:
///   node_count: number of elements to draw
///   node_color: color value (0-100) mapped to a gradient (e.g., green to brown)
///   flower_visibility: visibility of secondary node type
class OrganicGrowthEffect implements RuntimeEffect {
  @override
  String get type => 'organic_growth';

  @override
  void tick(EffectContext context, Map<String, dynamic> params) {
    final nodeCount = context.prop('node_count', defaultValue: 0.0).toInt();
    final nodeColorVal = context.prop('node_color', defaultValue: 100.0);
    final flowerVis = context.prop('flower_visibility', defaultValue: 0.0);

    if (nodeCount <= 0) return;

    // Map color from green (healthy = 100) to yellow/brown (wilted = 0)
    final healthPct = nodeColorVal.clamp(0.0, 100.0) / 100.0;
    final baseColor = Color.lerp(Colors.brown, Colors.green, healthPct) ?? Colors.green;

    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Center stem position
    final startX = context.size.width / 2;
    final startY = context.size.height * 0.8; // start from bottom up
    
    final spacing = context.size.height * 0.4 / (20); // space for max 20 nodes

    for (int i = 0; i < nodeCount; i++) {
      // Draw nodes alternating left and right
      final isLeft = i % 2 == 0;
      final xOffset = isLeft ? -15.0 : 15.0;
      final y = startY - (i * spacing);

      // Draw leaf shape (oval)
      context.canvas.save();
      context.canvas.translate(startX + xOffset, y);
      context.canvas.rotate(isLeft ? -pi/6 : pi/6);
      context.canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 20, height: 10), 
        paint
      );
      context.canvas.restore();
    }

    // Draw flowers if visible
    if (flowerVis > 50.0 && nodeCount >= 10) {
      final flowerPaint = Paint()
        ..color = Colors.pinkAccent
        ..style = PaintingStyle.fill;
        
      final topY = startY - (nodeCount * spacing) - 10;
      context.canvas.drawCircle(Offset(startX, topY), 12.0, flowerPaint);
      context.canvas.drawCircle(Offset(startX - 8, topY + 8), 8.0, flowerPaint);
      context.canvas.drawCircle(Offset(startX + 8, topY + 8), 8.0, flowerPaint);
      context.canvas.drawCircle(Offset(startX, topY + 12), 8.0, flowerPaint);
      
      final centerPaint = Paint()..color = Colors.yellow;
      context.canvas.drawCircle(Offset(startX, topY), 4.0, centerPaint);
    }
  }
}
