import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../runtime/runtime_world.dart';
import '../../../runtime/simulation/renderers/runtime_canvas_renderer.dart';
import '../interactions/simulation_environment.dart';
import 'experiment_asset_registry.dart';
import 'scene_definition.dart';

class ExperimentTheatre extends StatelessWidget {
  final RuntimeWorld world;
  final String environmentMode;
  final SceneDefinition scene;
  final ExperimentAssetRegistry assetRegistry;

  const ExperimentTheatre({
    super.key,
    required this.world,
    required this.environmentMode,
    required this.scene,
    this.assetRegistry = const ExperimentAssetRegistry(),
  });

  @override
  Widget build(BuildContext context) {
    final assets = assetRegistry.assetsFor(scene.assetIds);
    return Semantics(
      label: '${scene.primaryObject} scene with ${assets.length} visual assets',
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF020617)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SimulationEnvironment(mode: environmentMode),
            _SceneStructure(scene: scene),
            RuntimeCanvasView(
              canvas: world.simulationCanvas,
              backgroundColor: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneStructure extends StatelessWidget {
  final SceneDefinition scene;

  const _SceneStructure({required this.scene});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SceneStructurePainter(scene: scene),
      child: const SizedBox.expand(),
    );
  }
}

class _SceneStructurePainter extends CustomPainter {
  final SceneDefinition scene;

  const _SceneStructurePainter({required this.scene});

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackgroundIdentity(canvas, size);
    _paintZones(canvas, size);
    _paintSceneActors(canvas, size);
    _paintAnchors(canvas, size);
  }

  void _paintZones(Canvas canvas, Size size) {
    final zonePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.fill;
    final zoneStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final zone in scene.zones) {
      final rect = Rect.fromLTWH(
        size.width * zone.x,
        size.height * zone.y,
        size.width * zone.width,
        size.height * zone.height,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
      canvas.drawRRect(rrect, zonePaint);
      canvas.drawRRect(rrect, zoneStroke);
    }
  }

  void _paintAnchors(Canvas canvas, Size size) {
    final anchorPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final anchor in scene.anchors) {
      final center = Offset(size.width * anchor.x, size.height * anchor.y);
      canvas.drawCircle(center, 7, anchorPaint);
      canvas.drawCircle(
        center,
        16,
        Paint()
          ..color = anchorPaint.color.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _paintSceneActors(Canvas canvas, Size size) {
    switch (scene.id) {
      case 'waterCycle':
        _paintWaterCycle(canvas, size);
        break;
      case 'freeFall':
        _paintFreeFall(canvas, size);
        break;
      case 'pendulum':
        _paintPendulum(canvas, size);
        break;
      case 'plantGrowth':
        _paintPlantGrowth(canvas, size);
        break;
      case 'heartRate':
        _paintHeartRate(canvas, size);
        break;
      default:
        _paintGenericLab(canvas, size);
    }
  }

  void _paintWaterCycle(Canvas canvas, Size size) {
    final sun = Paint()..color = const Color(0xFFFACC15);
    canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.18), 38, sun);
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.88);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.42, size.height * 0.20),
        width: 150,
        height: 56,
      ),
      cloud,
    );
    final rain = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final x = size.width * (0.32 + i * 0.032);
      canvas.drawLine(
        Offset(x, size.height * 0.30),
        Offset(x - 8, size.height * 0.44),
        rain,
      );
    }
    final water = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.65);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.82),
        width: size.width * 0.52,
        height: 74,
      ),
      water,
    );
  }

  void _paintFreeFall(Canvas canvas, Size size) {
    final scale = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    final x = size.width * 0.20;
    canvas.drawLine(
      Offset(x, size.height * 0.14),
      Offset(x, size.height * 0.84),
      scale,
    );
    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.16 + i * 0.09);
      canvas.drawLine(Offset(x - 10, y), Offset(x + 10, y), scale);
    }
    final pathPaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.54, size.height * 0.45),
          width: 94,
          height: size.height * 0.66,
        ),
        const Radius.circular(28),
      ),
      pathPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.54, size.height * 0.30),
      24,
      Paint()..color = const Color(0xFFF97316),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.86, size.width, 26),
      Paint()..color = const Color(0xFF334155),
    );
  }

  void _paintPendulum(Canvas canvas, Size size) {
    final supportY = size.height * 0.18;
    final support = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.30, supportY),
      Offset(size.width * 0.70, supportY),
      support,
    );
    final pivot = Offset(size.width * 0.50, supportY);
    final bob = Offset(size.width * 0.62, size.height * 0.62);
    final trail = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawArc(
      Rect.fromCenter(
        center: pivot,
        width: size.width * 0.52,
        height: size.height * 0.72,
      ),
      math.pi * 0.28,
      math.pi * 0.44,
      false,
      trail,
    );
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    canvas.drawLine(pivot, bob, line);
    canvas.drawCircle(bob, 28, Paint()..color = const Color(0xFFF97316));
  }

  void _paintPlantGrowth(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.18),
      34,
      Paint()..color = const Color(0xFFFACC15),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.86),
        width: size.width * 0.72,
        height: 88,
      ),
      Paint()..color = const Color(0xFF854D0E),
    );
    final stem = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final base = Offset(size.width * 0.50, size.height * 0.78);
    final top = Offset(size.width * 0.50, size.height * 0.45);
    canvas.drawLine(base, top, stem);
    final leaf = Paint()..color = const Color(0xFF16A34A);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.43, size.height * 0.56),
        width: 86,
        height: 38,
      ),
      leaf,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.57, size.height * 0.50),
        width: 86,
        height: 38,
      ),
      leaf,
    );
  }

  void _paintHeartRate(Canvas canvas, Size size) {
    final heartCenter = Offset(size.width * 0.36, size.height * 0.48);
    final pulse = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(heartCenter, 80, pulse);
    canvas.drawCircle(
      heartCenter,
      42,
      Paint()..color = const Color(0xFFEF4444),
    );
    final ecg = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.56, size.height * 0.50)
      ..lineTo(size.width * 0.61, size.height * 0.50)
      ..lineTo(size.width * 0.64, size.height * 0.38)
      ..lineTo(size.width * 0.68, size.height * 0.64)
      ..lineTo(size.width * 0.72, size.height * 0.50)
      ..lineTo(size.width * 0.88, size.height * 0.50);
    canvas.drawPath(path, ecg);
  }

  void _paintGenericLab(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.50),
      70,
      Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.20),
    );
  }

  void _paintBackgroundIdentity(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    switch (scene.background) {
      case 'sky':
        final rect = Offset.zero & size;
        paint.shader = const LinearGradient(
          colors: [Color(0xFF082F49), Color(0xFF0EA5E9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
        canvas.drawRect(rect, paint);
        break;
      case 'physics':
        paint
          ..color = Colors.white.withValues(alpha: 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        for (var y = size.height * 0.15; y < size.height * 0.9; y += 30) {
          canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), paint);
        }
        break;
      case 'nature':
        final rect = Offset.zero & size;
        paint.shader = const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF15803D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
        canvas.drawRect(rect, paint);
        break;
      case 'medical':
        paint
          ..color = const Color(0xFF22C55E).withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        for (var x = 0.0; x < size.width; x += 28) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (var y = 0.0; y < size.height; y += 28) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SceneStructurePainter oldDelegate) {
    return oldDelegate.scene != scene;
  }
}
