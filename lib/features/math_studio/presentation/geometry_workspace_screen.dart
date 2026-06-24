import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/idp_colors.dart';
import '../domain/challenge.dart';
import '../domain/saved_exploration.dart';
import '../application/exploration_repository.dart';
import 'widgets/challenge_card.dart';
import 'widgets/concept_card.dart';
import 'widgets/observation_panel.dart';
import 'widgets/math_studio_workspace_shell.dart';

enum GeometryShape { triangle, rectangle, circle, polygon, pythagorean, angles }

class GeometryWorkspaceScreen extends StatefulWidget {
  final GeometryShape? initialShape;
  final String? discoveryPrompt;
  final MathChallenge? challenge;

  const GeometryWorkspaceScreen({
    super.key,
    this.initialShape,
    this.discoveryPrompt,
    this.challenge,
  });

  @override
  State<GeometryWorkspaceScreen> createState() =>
      _GeometryWorkspaceScreenState();
}

class _GeometryWorkspaceScreenState extends State<GeometryWorkspaceScreen> {
  late GeometryShape _shape;
  final TextEditingController _notesController = TextEditingController();
  bool _showLiveStats = true;

  @override
  void initState() {
    super.initState();
    _shape = widget.initialShape ?? GeometryShape.triangle;
    _resetShape();
  }

  // Storing points as Offset for easy dragging
  List<Offset> _points = [];
  int? _draggingIndex;

  // Circle specifics
  Offset _circleCenter = const Offset(150, 150);
  double _circleRadius = 80;
  bool _isDraggingCenter = false;
  bool _isDraggingRadius = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _resetShape() {
    switch (_shape) {
      case GeometryShape.triangle:
        _points = [
          const Offset(150, 50),
          const Offset(50, 200),
          const Offset(250, 200),
        ];
        break;
      case GeometryShape.rectangle:
        _points = [
          const Offset(50, 50),
          const Offset(250, 50),
          const Offset(250, 150),
          const Offset(50, 150),
        ];
        break;
      case GeometryShape.circle:
        _circleCenter = const Offset(150, 150);
        _circleRadius = 80;
        break;
      case GeometryShape.polygon:
        _points = [
          const Offset(150, 30),
          const Offset(250, 100),
          const Offset(200, 220),
          const Offset(100, 220),
          const Offset(50, 100),
        ];
        break;
      case GeometryShape.pythagorean:
        _points = [
          const Offset(150, 50),
          const Offset(150, 200),
          const Offset(250, 200),
        ];
        break;
      case GeometryShape.angles:
        _points = [
          const Offset(100, 100),
          const Offset(200, 200),
          const Offset(100, 200),
          const Offset(200, 100),
        ];
        break;
    }
    setState(() {});
  }

  double _calculateDistance(Offset p1, Offset p2) {
    return math.sqrt(math.pow(p2.dx - p1.dx, 2) + math.pow(p2.dy - p1.dy, 2));
  }

  double _calculateArea() {
    if (_shape == GeometryShape.circle) {
      return math.pi * _circleRadius * _circleRadius;
    }

    // Shoelace formula for polygon area
    if (_points.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < _points.length; i++) {
      int j = (i + 1) % _points.length;
      area += _points[i].dx * _points[j].dy;
      area -= _points[j].dx * _points[i].dy;
    }
    return area.abs() / 2.0;
  }

  double _calculatePerimeter() {
    if (_shape == GeometryShape.circle) {
      return 2 * math.pi * _circleRadius;
    }

    if (_points.length < 2) return 0;
    double perimeter = 0;
    for (int i = 0; i < _points.length; i++) {
      int j = (i + 1) % _points.length;
      perimeter += _calculateDistance(_points[i], _points[j]);
    }
    return perimeter;
  }

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;

    if (_shape == GeometryShape.circle) {
      if (_calculateDistance(pos, _circleCenter) < 20) {
        _isDraggingCenter = true;
      } else if ((_calculateDistance(pos, _circleCenter) - _circleRadius)
              .abs() <
          20) {
        _isDraggingRadius = true;
      }
      return;
    }

    for (int i = 0; i < _points.length; i++) {
      if (_calculateDistance(pos, _points[i]) < 30) {
        _draggingIndex = i;
        break;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (_shape == GeometryShape.circle) {
        if (_isDraggingCenter) {
          _circleCenter += details.delta;
        } else if (_isDraggingRadius) {
          _circleRadius = _calculateDistance(
            _circleCenter,
            details.localPosition,
          );
        }
        return;
      }

      if (_draggingIndex != null) {
        Offset newPos = _points[_draggingIndex!] + details.delta;

        if (_shape == GeometryShape.rectangle) {
          // Keep it a rectangle by moving adjacent points
          int i = _draggingIndex!;
          _points[i] = newPos;

          if (i == 0) {
            _points[1] = Offset(_points[1].dx, newPos.dy);
            _points[3] = Offset(newPos.dx, _points[3].dy);
          } else if (i == 1) {
            _points[0] = Offset(_points[0].dx, newPos.dy);
            _points[2] = Offset(newPos.dx, _points[2].dy);
          } else if (i == 2) {
            _points[3] = Offset(_points[3].dx, newPos.dy);
            _points[1] = Offset(newPos.dx, _points[1].dy);
          } else if (i == 3) {
            _points[2] = Offset(_points[2].dx, newPos.dy);
            _points[0] = Offset(newPos.dx, _points[0].dy);
          }
        } else {
          _points[_draggingIndex!] = newPos;
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _draggingIndex = null;
    _isDraggingCenter = false;
    _isDraggingRadius = false;
  }

  @override
  Widget build(BuildContext context) {
    return MathStudioWorkspaceShell(
      title: 'Geometry Workspace',
      accentColor: const Color(0xFF0D9488),
      actions: [
        IconButton(
          icon: const Icon(Icons.save_rounded),
          onPressed: () async {
            final repo = await ExplorationRepository.create();
            await repo.saveExploration(
              SavedExploration.create(
                title: 'Geometry Snapshot: ${_shape.name}',
                type: ExplorationType.geometry,
                data: {'shape': _shape.name, 'notes': _notesController.text},
              ),
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Workspace saved!')));
          },
        ),
      ],
      children: [
        if (widget.discoveryPrompt != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0D9488).withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF0F766E),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.discoveryPrompt!,
                    style: const TextStyle(
                      color: Color(0xFF134E4A),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.discoveryPrompt != null) const SizedBox(height: 12),
        if (widget.challenge != null)
          ChallengeCard(
            challenge: widget.challenge!,
            isCompleted: widget.challenge!.verifier({
              'area': _calculateArea(),
              'perimeter': _calculatePerimeter(),
            }),
          ),
        if (widget.challenge != null) const SizedBox(height: 12),
        ConceptCard(
          title: _shape == GeometryShape.pythagorean
              ? 'Pythagorean Theorem'
              : 'Geometry Properties',
          description: _shape == GeometryShape.pythagorean
              ? 'In a right-angled triangle, the square of the hypotenuse is equal to the sum of the squares of the other two sides.'
              : 'Geometry is the study of shapes, sizes, and properties of space.',
          example: _shape == GeometryShape.pythagorean
              ? 'Used in construction to ensure walls are perfectly square (the 3-4-5 rule).'
              : 'Architects use geometry to design stable and aesthetically pleasing buildings.',
          icon: Icons.architecture_rounded,
          color: const Color(0xFF0D9488),
        ),
        if (_shape != GeometryShape.pythagorean &&
            _shape != GeometryShape.angles)
          const SizedBox(height: 12),
        if (_shape != GeometryShape.pythagorean &&
            _shape != GeometryShape.angles)
          _buildToolbar(),
        if (_shape != GeometryShape.pythagorean &&
            _shape != GeometryShape.angles)
          const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.05,
          child: Stack(
            children: [
              GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: IDPColors.border),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CustomPaint(
                      painter: _GeometryPainter(
                        shape: _shape,
                        points: _points,
                        circleCenter: _circleCenter,
                        circleRadius: _circleRadius,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(top: 16, right: 16, child: _buildLiveStats()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ObservationPanel(controller: _notesController),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceAround,
        children: GeometryShape.values.map((s) {
          final isSelected = _shape == s;
          return InkWell(
            onTap: () {
              setState(() {
                _shape = s;
                _resetShape();
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0D9488).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : IDPColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLiveStats() {
    if (!_showLiveStats) {
      return FloatingActionButton.small(
        onPressed: () => setState(() => _showLiveStats = true),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D9488),
        child: const Icon(Icons.calculate),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Calculations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: IDPColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _showLiveStats = false),
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Area: ${_calculateArea().toStringAsFixed(1)} px²',
            style: const TextStyle(
              color: Color(0xFF0D9488),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Perimeter: ${_calculatePerimeter().toStringAsFixed(1)} px',
            style: const TextStyle(
              color: Color(0xFF0D9488),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_shape == GeometryShape.triangle) ...[
            const SizedBox(height: 8),
            const Text(
              'Drag corners to edit.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class _GeometryPainter extends CustomPainter {
  final GeometryShape shape;
  final List<Offset> points;
  final Offset circleCenter;
  final double circleRadius;

  _GeometryPainter({
    required this.shape,
    required this.points,
    required this.circleCenter,
    required this.circleRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF0D9488).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..style = PaintingStyle.fill;

    if (shape == GeometryShape.circle) {
      canvas.drawCircle(circleCenter, circleRadius, fillPaint);
      canvas.drawCircle(circleCenter, circleRadius, strokePaint);
      canvas.drawCircle(circleCenter, 6, pointPaint); // Center handle
      canvas.drawCircle(
        circleCenter + Offset(circleRadius, 0),
        6,
        pointPaint,
      ); // Radius handle
    } else if (shape == GeometryShape.pythagorean) {
      if (points.length >= 3) {
        final path = Path()
          ..moveTo(points[0].dx, points[0].dy)
          ..lineTo(points[1].dx, points[1].dy)
          ..lineTo(points[2].dx, points[2].dy)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);

        // Draw squares on each side
        for (int i = 0; i < 3; i++) {
          final p1 = points[i];
          final p2 = points[(i + 1) % 3];
          final dx = p2.dx - p1.dx;
          final dy = p2.dy - p1.dy;
          final p3 = Offset(p2.dx + dy, p2.dy - dx);
          final p4 = Offset(p1.dx + dy, p1.dy - dx);
          final squarePath = Path()
            ..moveTo(p1.dx, p1.dy)
            ..lineTo(p2.dx, p2.dy)
            ..lineTo(p3.dx, p3.dy)
            ..lineTo(p4.dx, p4.dy)
            ..close();
          canvas.drawPath(
            squarePath,
            Paint()
              ..color = Colors.orange.withValues(alpha: 0.3)
              ..style = PaintingStyle.fill,
          );
          canvas.drawPath(
            squarePath,
            Paint()
              ..color = Colors.orange
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
      for (var p in points) {
        canvas.drawCircle(p, 8, pointPaint);
      }
    } else if (shape == GeometryShape.angles) {
      if (points.length >= 4) {
        // Draw two intersecting lines
        canvas.drawLine(points[0], points[1], strokePaint);
        canvas.drawLine(points[2], points[3], strokePaint);
      }
      for (var p in points) {
        canvas.drawCircle(p, 8, pointPaint);
      }
    } else {
      if (points.length >= 3) {
        final path = Path()..moveTo(points[0].dx, points[0].dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
      }

      for (var p in points) {
        canvas.drawCircle(p, 8, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GeometryPainter oldDelegate) => true;
}
