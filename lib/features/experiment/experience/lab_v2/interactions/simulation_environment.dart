import 'package:flutter/material.dart';

class SimulationEnvironment extends StatelessWidget {
  final String mode;

  const SimulationEnvironment({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(mode);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: CustomPaint(painter: _EnvironmentPainter(mode: mode)),
    );
  }

  List<Color> _colorsFor(String mode) {
    switch (mode.toLowerCase()) {
      case 'space':
        return const [Color(0xFF020617), Color(0xFF172554)];
      case 'nature':
      case 'outdoor':
        return const [Color(0xFFDBEAFE), Color(0xFFDCFCE7)];
      case 'physics_room':
      case 'physics':
        return const [Color(0xFFEFF6FF), Color(0xFFF8FAFC)];
      case 'chemistry_bench':
      case 'chemistry':
        return const [Color(0xFFFFF7ED), Color(0xFFE0F2FE)];
      case 'laboratory':
      case 'lab':
        return const [Color(0xFFE2E8F0), Color(0xFFF8FAFC)];
      case 'microscope':
        return const [Color(0xFFE0F2FE), Color(0xFFFAE8FF)];
      case 'classroom':
        return const [Color(0xFFEFF6FF), Color(0xFFFFFBEB)];
      default:
        return const [Color(0xFFE2E8F0), Color(0xFFF8FAFC)];
    }
  }
}

class _EnvironmentPainter extends CustomPainter {
  final String mode;

  const _EnvironmentPainter({required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnvironmentPainter oldDelegate) {
    return oldDelegate.mode != mode;
  }
}
