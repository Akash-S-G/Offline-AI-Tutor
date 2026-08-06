import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/idp_colors.dart';

class CircleVisualizationPainter extends CustomPainter {
  final double radius;
  CircleVisualizationPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Normalize radius to fit
    final maxRadius = size.height / 2 - 10;
    // Draw a base circle for scale
    canvas.drawCircle(
      center,
      maxRadius,
      Paint()
        ..color = IDPColors.outlineVariant
        ..style = PaintingStyle.fill,
    );

    // Dynamic radius drawing
    final drawRadius = math.min(math.max(radius, 5.0), maxRadius);
    final fillPaint = Paint()
      ..color = IDPColors.tertiary.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = IDPColors.tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, drawRadius, fillPaint);
    canvas.drawCircle(center, drawRadius, strokePaint);

    // Draw radius line
    canvas.drawLine(center, center + Offset(drawRadius, 0), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CircleVisualizationPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class PythagoreanPainter extends CustomPainter {
  final double a;
  final double b;
  PythagoreanPainter(this.a, this.b);

  @override
  void paint(Canvas canvas, Size size) {
    if (a <= 0 || b <= 0) return;

    // Normalize
    final maxDim = math.max(a, b);
    final scale = (size.height - 40) / maxDim;

    final pA = a * scale;
    final pB = b * scale;

    final startX = (size.width - pB) / 2;
    final startY = size.height - 20;

    final p1 = Offset(startX, startY);
    final p2 = Offset(startX + pB, startY);
    final p3 = Offset(startX, startY - pA);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    final fillPaint = Paint()
      ..color = IDPColors.tertiary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = IDPColors.tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Right angle marker
    canvas.drawLine(
      p1 + const Offset(10, 0),
      p1 + const Offset(10, -10),
      strokePaint,
    );
    canvas.drawLine(
      p1 + const Offset(10, -10),
      p1 + const Offset(0, -10),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant PythagoreanPainter oldDelegate) =>
      oldDelegate.a != a || oldDelegate.b != b;
}

class InterestPainter extends CustomPainter {
  final double principal;
  final double rate;
  final double time;

  InterestPainter(this.principal, this.rate, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    if (principal <= 0 || time <= 0) return;

    final interest = (principal * rate * time) / 100;
    final total = principal + interest;

    // Draw bar chart
    final pWidth = size.width * 0.3;
    final gap = size.width * 0.1;
    final iWidth = size.width * 0.3;

    final maxVal = math.max(total, 1.0);
    final scale = size.height / maxVal;

    final pPaint = Paint()..color = IDPColors.tertiary;
    final iPaint = Paint()..color = IDPColors.primary;

    // Principal Rect
    canvas.drawRect(
      Rect.fromLTRB(
        gap,
        size.height - (principal * scale),
        gap + pWidth,
        size.height,
      ),
      pPaint,
    );

    // Total Rect (Principal + Interest stacked)
    final start2 = gap + pWidth + gap;
    canvas.drawRect(
      Rect.fromLTRB(
        start2,
        size.height - (principal * scale),
        start2 + iWidth,
        size.height,
      ),
      pPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        start2,
        size.height - (total * scale),
        start2 + iWidth,
        size.height - (principal * scale),
      ),
      iPaint,
    );
  }

  @override
  bool shouldRepaint(covariant InterestPainter oldDelegate) =>
      oldDelegate.principal != principal ||
      oldDelegate.rate != rate ||
      oldDelegate.time != time;
}

class SpeedPainter extends CustomPainter {
  final double distance;
  final double time;
  SpeedPainter(this.distance, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    if (time <= 0 || distance < 0) return;

    final trackY = size.height / 2;
    canvas.drawLine(
      Offset(0, trackY),
      Offset(size.width, trackY),
      Paint()
        ..color = IDPColors.outlineVariant
        ..strokeWidth = 4,
    );

    // Simulate position (normalize distance to width)
    final dx = math.min(distance, 100.0) / 100.0 * size.width;

    canvas.drawCircle(
      Offset(dx, trackY),
      12,
      Paint()..color = IDPColors.tertiary,
    );
  }

  @override
  bool shouldRepaint(covariant SpeedPainter oldDelegate) =>
      oldDelegate.distance != distance || oldDelegate.time != time;
}

class PercentagePainter extends CustomPainter {
  final double part;
  final double whole;
  PercentagePainter(this.part, this.whole);

  @override
  void paint(Canvas canvas, Size size) {
    if (whole <= 0) return;

    final barRect = Rect.fromLTWH(0, size.height / 2 - 10, size.width, 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(10)),
      Paint()..color = IDPColors.outlineVariant,
    );

    final ratio = math.min(math.max(part / whole, 0.0), 1.0);
    final fillRect = Rect.fromLTWH(
      0,
      size.height / 2 - 10,
      size.width * ratio,
      20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(10)),
      Paint()..color = IDPColors.tertiary,
    );
  }

  @override
  bool shouldRepaint(covariant PercentagePainter oldDelegate) =>
      oldDelegate.part != part || oldDelegate.whole != whole;
}
