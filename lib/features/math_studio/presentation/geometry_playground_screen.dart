import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/idp_colors.dart';
import 'widgets/math_studio_workspace_shell.dart';
import 'widgets/observation_panel.dart';

enum PlaygroundShapeType { triangle, rectangle, circle }

class PlaygroundShape {
  final String id;
  final PlaygroundShapeType type;
  List<Offset> points;
  Offset center;
  double radius;
  final Color color;

  PlaygroundShape({
    required this.id,
    required this.type,
    this.points = const [],
    this.center = Offset.zero,
    this.radius = 0,
    required this.color,
  });

  PlaygroundShape copy() {
    return PlaygroundShape(
      id: id,
      type: type,
      points: List.from(points),
      center: center,
      radius: radius,
      color: color,
    );
  }
}

class GeometryPlaygroundScreen extends StatefulWidget {
  const GeometryPlaygroundScreen({super.key});

  @override
  State<GeometryPlaygroundScreen> createState() =>
      _GeometryPlaygroundScreenState();
}

class _GeometryPlaygroundScreenState extends State<GeometryPlaygroundScreen> {
  final List<PlaygroundShape> _shapes = [];
  final TextEditingController _notesController = TextEditingController();

  // Interaction state
  PlaygroundShape? _draggingShape;
  int? _draggingPointIndex;
  bool _isDraggingCenter = false;
  bool _isDraggingRadius = false;
  bool _isDraggingBody = false;

  final List<Color> _palette = [
    IDPColors.primary,
    IDPColors.secondary,
    IDPColors.tertiary,
    const Color(0xFFD97706),
    const Color(0xFF8B5CF6),
  ];
  int _colorIndex = 0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addShape(PlaygroundShapeType type) {
    final color = _palette[_colorIndex % _palette.length];
    _colorIndex++;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    PlaygroundShape newShape;
    switch (type) {
      case PlaygroundShapeType.triangle:
        newShape = PlaygroundShape(
          id: id,
          type: type,
          color: color,
          points: [
            const Offset(150, 50),
            const Offset(50, 200),
            const Offset(250, 200),
          ],
        );
        break;
      case PlaygroundShapeType.rectangle:
        newShape = PlaygroundShape(
          id: id,
          type: type,
          color: color,
          points: [
            const Offset(50, 50),
            const Offset(200, 50),
            const Offset(200, 150),
            const Offset(50, 150),
          ],
        );
        break;
      case PlaygroundShapeType.circle:
        newShape = PlaygroundShape(
          id: id,
          type: type,
          color: color,
          center: const Offset(150, 150),
          radius: 80,
        );
        break;
    }

    setState(() {
      _shapes.add(newShape);
    });
  }

  double _distance(Offset p1, Offset p2) {
    return math.sqrt(math.pow(p2.dx - p1.dx, 2) + math.pow(p2.dy - p1.dy, 2));
  }

  bool _isPointInPolygon(Offset p, List<Offset> polygon) {
    bool isInside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].dy > p.dy) != (polygon[j].dy > p.dy)) &&
          (p.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (p.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx)) {
        isInside = !isInside;
      }
    }
    return isInside;
  }

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;

    // Check handles from front to back (top to bottom painted)
    for (int i = _shapes.length - 1; i >= 0; i--) {
      final shape = _shapes[i];

      if (shape.type == PlaygroundShapeType.circle) {
        if (_distance(pos, shape.center) < 20) {
          _draggingShape = shape;
          _isDraggingCenter = true;
          return;
        } else if ((_distance(pos, shape.center) - shape.radius).abs() < 20) {
          _draggingShape = shape;
          _isDraggingRadius = true;
          return;
        }
      } else {
        for (int j = 0; j < shape.points.length; j++) {
          if (_distance(pos, shape.points[j]) < 30) {
            _draggingShape = shape;
            _draggingPointIndex = j;
            return;
          }
        }
      }
    }

    // Check bodies (fill) for moving the whole shape
    for (int i = _shapes.length - 1; i >= 0; i--) {
      final shape = _shapes[i];
      if (shape.type == PlaygroundShapeType.circle) {
        if (_distance(pos, shape.center) <= shape.radius) {
          _draggingShape = shape;
          _isDraggingBody = true;
          return;
        }
      } else {
        if (_isPointInPolygon(pos, shape.points)) {
          _draggingShape = shape;
          _isDraggingBody = true;
          return;
        }
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggingShape == null) return;

    setState(() {
      final shape = _draggingShape!;
      final delta = details.delta;

      if (_isDraggingBody) {
        if (shape.type == PlaygroundShapeType.circle) {
          shape.center += delta;
        } else {
          for (int i = 0; i < shape.points.length; i++) {
            shape.points[i] += delta;
          }
        }
      } else if (shape.type == PlaygroundShapeType.circle) {
        if (_isDraggingCenter) {
          shape.center += delta;
        } else if (_isDraggingRadius) {
          shape.radius = _distance(shape.center, details.localPosition);
          if (shape.radius < 10) shape.radius = 10;
        }
      } else if (_draggingPointIndex != null) {
        final i = _draggingPointIndex!;
        final newPos = shape.points[i] + delta;

        if (shape.type == PlaygroundShapeType.rectangle) {
          // Keep it a rectangle
          shape.points[i] = newPos;
          if (i == 0) {
            shape.points[1] = Offset(shape.points[1].dx, newPos.dy);
            shape.points[3] = Offset(newPos.dx, shape.points[3].dy);
          } else if (i == 1) {
            shape.points[0] = Offset(shape.points[0].dx, newPos.dy);
            shape.points[2] = Offset(newPos.dx, shape.points[2].dy);
          } else if (i == 2) {
            shape.points[3] = Offset(shape.points[3].dx, newPos.dy);
            shape.points[1] = Offset(newPos.dx, shape.points[1].dy);
          } else if (i == 3) {
            shape.points[2] = Offset(shape.points[2].dx, newPos.dy);
            shape.points[0] = Offset(newPos.dx, shape.points[0].dy);
          }
        } else {
          shape.points[i] = newPos;
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _draggingShape = null;
    _draggingPointIndex = null;
    _isDraggingCenter = false;
    _isDraggingRadius = false;
    _isDraggingBody = false;
  }

  @override
  Widget build(BuildContext context) {
    return MathStudioWorkspaceShell(
      title: '2D Shape Playground',
      accentColor: IDPColors.tertiary,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded),
          tooltip: 'Clear Canvas',
          onPressed: () {
            setState(() {
              _shapes.clear();
            });
          },
        ),
      ],
      children: [
        Container(
          color: IDPColors.surface,
          padding: const EdgeInsets.symmetric(vertical: IDPSpacing.md, horizontal: IDPSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAddButton(
                icon: Icons.change_history_rounded,
                label: 'Triangle',
                onTap: () => _addShape(PlaygroundShapeType.triangle),
              ),
              _buildAddButton(
                icon: Icons.crop_square_rounded,
                label: 'Rectangle',
                onTap: () => _addShape(PlaygroundShapeType.rectangle),
              ),
              _buildAddButton(
                icon: Icons.radio_button_unchecked_rounded,
                label: 'Circle',
                onTap: () => _addShape(PlaygroundShapeType.circle),
              ),
            ],
          ),
        ),
        const SizedBox(height: IDPSpacing.md),
        AspectRatio(
          aspectRatio: 1.05,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Container(
              decoration: BoxDecoration(
                color: IDPColors.surface,
                borderRadius: BorderRadius.circular(IDPRadius.md),
                border: Border.all(color: IDPColors.outlineVariant),
              ),
              width: double.infinity,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(IDPRadius.md),
                child: CustomPaint(
                  painter: _PlaygroundPainter(shapes: _shapes),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: IDPSpacing.md),
        ObservationPanel(controller: _notesController),
      ],
    );
  }

  Widget _buildAddButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(IDPRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: IDPSpacing.sm, horizontal: 12),
        decoration: BoxDecoration(
          color: IDPColors.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(IDPRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: IDPColors.tertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: IDPTypography.labelMedium.copyWith(
                color: IDPColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaygroundPainter extends CustomPainter {
  final List<PlaygroundShape> shapes;

  _PlaygroundPainter({required this.shapes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in shapes) {
      final fillPaint = Paint()
        ..color = shape.color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = shape.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final pointPaint = Paint()
        ..color = shape.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      if (shape.type == PlaygroundShapeType.circle) {
        canvas.drawCircle(shape.center, shape.radius, fillPaint);
        canvas.drawCircle(shape.center, shape.radius, strokePaint);
        canvas.drawCircle(shape.center, 6, pointPaint); // Center handle
        canvas.drawCircle(
          shape.center + Offset(shape.radius, 0),
          6,
          pointPaint,
        ); // Radius handle
        _paintMeasurementLabel(
          canvas,
          'r ${_formatMeasure(shape.radius)}',
          shape.center + Offset(shape.radius / 2, -18),
        );
      } else {
        if (shape.points.length >= 3) {
          final path = Path()..moveTo(shape.points[0].dx, shape.points[0].dy);
          for (int i = 1; i < shape.points.length; i++) {
            path.lineTo(shape.points[i].dx, shape.points[i].dy);
          }
          path.close();
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, strokePaint);
          _paintSideMeasurements(canvas, shape.points);
        }

        for (var p in shape.points) {
          canvas.drawCircle(p, 8, pointPaint);
        }
      }
    }
  }

  void _paintSideMeasurements(Canvas canvas, List<Offset> vertices) {
    if (vertices.length < 2) return;
    for (int i = 0; i < vertices.length; i++) {
      _paintSegmentMeasurement(
        canvas,
        vertices[i],
        vertices[(i + 1) % vertices.length],
      );
    }
  }

  void _paintSegmentMeasurement(Canvas canvas, Offset a, Offset b) {
    final length = math.sqrt(
      math.pow(b.dx - a.dx, 2) + math.pow(b.dy - a.dy, 2),
    );
    final midpoint = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final normal = _segmentNormal(a, b);
    _paintMeasurementLabel(
      canvas,
      _formatMeasure(length),
      midpoint + normal * 14,
    );
  }

  Offset _segmentNormal(Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) return const Offset(0, -1);
    return Offset(-dy / length, dx / length);
  }

  String _formatMeasure(double value) {
    final cm = value / 10;
    return '${cm.toStringAsFixed(1)} cm';
  }

  void _paintMeasurementLabel(Canvas canvas, String text, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: IDPTypography.caption.copyWith(
          color: IDPColors.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: center,
      width: painter.width + 12,
      height: painter.height + 7,
    );
    final background = Paint()
      ..color = IDPColors.surface.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = IDPColors.outline.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(IDPRadius.sm));
    canvas.drawRRect(rrect, background);
    canvas.drawRRect(rrect, border);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PlaygroundPainter oldDelegate) => true;
}
