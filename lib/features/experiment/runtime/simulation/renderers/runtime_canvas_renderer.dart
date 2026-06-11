import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../canvas/runtime_simulation_canvas.dart';
import '../models/runtime_actor.dart';

class RuntimeCanvasView extends StatelessWidget {
  final RuntimeSimulationCanvas canvas;
  final Color backgroundColor;

  const RuntimeCanvasView({
    super.key,
    required this.canvas,
    this.backgroundColor = const Color(0xFFF8FAFC),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: canvas,
      builder: (context, _) {
        return CustomPaint(
          painter: RuntimeCanvasRenderer(
            actors: canvas.actors,
            backgroundColor: backgroundColor,
            onRendered: canvas.markRendered,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class RuntimeCanvasRenderer extends CustomPainter {
  final List<RuntimeActor> actors;
  final Color backgroundColor;
  final VoidCallback? onRendered;

  const RuntimeCanvasRenderer({
    required this.actors,
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.onRendered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    for (final actor in actors) {
      if (!actor.visible || actor.opacity <= 0) continue;
      _paintActor(canvas, actor);
    }
    onRendered?.call();
  }

  void _paintActor(Canvas canvas, RuntimeActor actor) {
    canvas.save();
    canvas.translate(actor.positionX, actor.positionY);
    canvas.rotate(actor.rotation);
    canvas.scale(actor.scale);
    final color = actor.color().withAlpha(
      (actor.opacity.clamp(0, 1).toDouble() * 255).round(),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = _double(actor.state['strokeWidth'], fallback: 3);
    switch (actor.type) {
      case 'circle':
        _paintCircle(canvas, actor, paint);
      case 'rectangle':
        _paintRectangle(canvas, actor, paint);
      case 'line':
        _paintLine(canvas, actor, paint);
      case 'arrow':
        _paintArrow(canvas, actor, paint);
      case 'text':
        _paintText(canvas, actor, color);
      case 'image':
        _paintImagePlaceholder(canvas, actor, paint);
      case 'particle':
        _paintParticle(canvas, actor, paint);
      default:
        _paintRectangle(canvas, actor, paint);
    }
    canvas.restore();
  }

  void _paintCircle(Canvas canvas, RuntimeActor actor, Paint paint) {
    final radius = _double(actor.state['radius'], fallback: 18);
    canvas.drawCircle(Offset.zero, radius, paint);
  }

  void _paintRectangle(Canvas canvas, RuntimeActor actor, Paint paint) {
    final width = _double(actor.state['width'], fallback: 64);
    final height = _double(actor.state['height'], fallback: 40);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      paint,
    );
  }

  void _paintLine(Canvas canvas, RuntimeActor actor, Paint paint) {
    paint.style = PaintingStyle.stroke;
    final x2 = _double(
      actor.state['x2'],
      fallback: _double(actor.state['width'], fallback: 80),
    );
    final y2 = _double(actor.state['y2']);
    canvas.drawLine(Offset.zero, Offset(x2, y2), paint);
  }

  void _paintArrow(Canvas canvas, RuntimeActor actor, Paint paint) {
    _paintLine(canvas, actor, paint);
    final x2 = _double(
      actor.state['x2'],
      fallback: _double(actor.state['width'], fallback: 80),
    );
    final y2 = _double(actor.state['y2']);
    final angle = math.atan2(y2, x2);
    final head = _double(actor.state['headSize'], fallback: 12);
    final path = Path()
      ..moveTo(x2, y2)
      ..lineTo(
        x2 - head * math.cos(angle - math.pi / 6),
        y2 - head * math.sin(angle - math.pi / 6),
      )
      ..moveTo(x2, y2)
      ..lineTo(
        x2 - head * math.cos(angle + math.pi / 6),
        y2 - head * math.sin(angle + math.pi / 6),
      );
    canvas.drawPath(path, paint);
  }

  void _paintText(Canvas canvas, RuntimeActor actor, Color color) {
    final text = actor.state['text']?.toString() ?? actor.id;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: _double(actor.state['fontSize'], fallback: 18),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _double(actor.state['width'], fallback: 220));
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  }

  void _paintImagePlaceholder(Canvas canvas, RuntimeActor actor, Paint paint) {
    _paintRectangle(canvas, actor, paint..style = PaintingStyle.stroke);
    final label = actor.state['asset']?.toString() ?? 'image';
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: paint.color, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _double(actor.state['width'], fallback: 80));
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  }

  void _paintParticle(Canvas canvas, RuntimeActor actor, Paint paint) {
    final radius = _double(actor.state['radius'], fallback: 5);
    canvas.drawCircle(Offset.zero, radius, paint);
  }

  @override
  bool shouldRepaint(covariant RuntimeCanvasRenderer oldDelegate) {
    return oldDelegate.actors != actors ||
        oldDelegate.backgroundColor != backgroundColor;
  }

  static double _double(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
