import 'package:flutter/material.dart';
import '../../runtime/runtime_world.dart';
import 'measurement_tool.dart';

/// On-screen ruler that scales its tick marks with the current pendulum length.
/// Shows major ticks every 0.5m, minor ticks every 0.1m.
class RulerTool implements MeasurementTool {
  @override
  String get type => 'ruler';

  @override
  Widget buildOverlay(RuntimeWorld world, BuildContext context) {
    return Positioned(
      left: 12,
      top: 80,
      bottom: 80,
      child: _RulerWidget(world: world),
    );
  }
}

class _RulerWidget extends StatelessWidget {
  final RuntimeWorld world;
  const _RulerWidget({required this.world});

  @override
  Widget build(BuildContext context) {
    final rawLength = world.variables.getValue('var_length');
    final length = rawLength != null ? (rawLength as num).toDouble() : 1.0;

    return Container(
      width: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: CustomPaint(
        painter: _RulerPainter(lengthM: length.clamp(0.5, 5.0)),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double lengthM;
  _RulerPainter({required this.lengthM});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.white70..strokeWidth = 1;
    final majorPaint = Paint()..color = Colors.tealAccent..strokeWidth = 1.5;

    const totalMarks = 10;
    final stepHeight = size.height / totalMarks;

    for (int i = 0; i <= totalMarks; i++) {
      final y = i * stepHeight;
      final isMajor = i % 2 == 0;
      final tickWidth = isMajor ? 20.0 : 12.0;
      final paint = isMajor ? majorPaint : linePaint;
      canvas.drawLine(Offset(size.width - tickWidth, y), Offset(size.width, y), paint);

      if (isMajor) {
        final label = '${(i * lengthM / totalMarks).toStringAsFixed(1)}m';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.white70, fontSize: 8),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(0, y - 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) => old.lengthM != lengthM;
}
