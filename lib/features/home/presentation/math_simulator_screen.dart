import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class MathSimulatorScreen extends StatefulWidget {
  const MathSimulatorScreen({super.key});

  @override
  State<MathSimulatorScreen> createState() => _MathSimulatorScreenState();
}

class _MathSimulatorScreenState extends State<MathSimulatorScreen> {
  final TextEditingController _formulaController = TextEditingController(
    text: 'sin(x)',
  );
  double _xMin = -10;
  double _xMax = 10;
  String? _graphError;

  _GeometryShape _shape = _GeometryShape.circle;
  double _a = 5;
  double _b = 4;

  @override
  void dispose() {
    _formulaController.dispose();
    super.dispose();
  }

  void _refreshGraph() {
    setState(() {
      _graphError = null;
    });
  }

  double get _area {
    switch (_shape) {
      case _GeometryShape.circle:
        return math.pi * _a * _a;
      case _GeometryShape.rectangle:
        return _a * _b;
      case _GeometryShape.rightTriangle:
        return 0.5 * _a * _b;
    }
  }

  double get _perimeter {
    switch (_shape) {
      case _GeometryShape.circle:
        return 2 * math.pi * _a;
      case _GeometryShape.rectangle:
        return 2 * (_a + _b);
      case _GeometryShape.rightTriangle:
        return _a + _b + math.sqrt(_a * _a + _b * _b);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Math and Geometry Simulator'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.show_chart_rounded), text: 'Formula 2D'),
              Tab(icon: Icon(Icons.architecture_rounded), text: 'Geometry 2D'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFormulaTab(),
            _buildGeometryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Formula Plotter (2D)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use formulas like: sin(x), x^2, x^3 - 4*x, sqrt(abs(x)), log(x)',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _formulaController,
            decoration: const InputDecoration(
              labelText: 'f(x) =',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _refreshGraph(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('x min: ${_xMin.toStringAsFixed(1)}'),
                    Slider(
                      min: -50,
                      max: -1,
                      value: _xMin,
                      onChanged: (value) {
                        if (value < _xMax - 1) {
                          setState(() {
                            _xMin = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('x max: ${_xMax.toStringAsFixed(1)}'),
                    Slider(
                      min: 1,
                      max: 50,
                      value: _xMax,
                      onChanged: (value) {
                        if (value > _xMin + 1) {
                          setState(() {
                            _xMax = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _refreshGraph,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Simulate Formula'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: _FormulaGraphCard(
              expressionText: _formulaController.text.trim(),
              xMin: _xMin,
              xMax: _xMax,
              onError: (message) {
                if (_graphError != message && mounted) {
                  setState(() {
                    _graphError = message;
                  });
                }
              },
              onSuccess: () {
                if (_graphError != null && mounted) {
                  setState(() {
                    _graphError = null;
                  });
                }
              },
            ),
          ),
          if (_graphError != null) ...[
            const SizedBox(height: 10),
            Text(
              _graphError!,
              style: const TextStyle(color: Color(0xFFB91C1C)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeometryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Geometry Simulator (2D)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<_GeometryShape>(
            initialValue: _shape,
            items: const [
              DropdownMenuItem(
                value: _GeometryShape.circle,
                child: Text('Circle'),
              ),
              DropdownMenuItem(
                value: _GeometryShape.rectangle,
                child: Text('Rectangle'),
              ),
              DropdownMenuItem(
                value: _GeometryShape.rightTriangle,
                child: Text('Right Triangle'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _shape = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Shape',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(_shape == _GeometryShape.circle
              ? 'Radius: ${_a.toStringAsFixed(1)}'
              : 'Dimension A: ${_a.toStringAsFixed(1)}'),
          Slider(
            min: 1,
            max: 30,
            value: _a,
            onChanged: (value) {
              setState(() {
                _a = value;
              });
            },
          ),
          if (_shape != _GeometryShape.circle) ...[
            Text('Dimension B: ${_b.toStringAsFixed(1)}'),
            Slider(
              min: 1,
              max: 30,
              value: _b,
              onChanged: (value) {
                setState(() {
                  _b = value;
                });
              },
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomPaint(
                  painter: _GeometryPainter(
                    shape: _shape,
                    a: _a,
                    b: _b,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Area: ${_area.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Perimeter: ${_perimeter.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  Text(_formulaDescription()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formulaDescription() {
    switch (_shape) {
      case _GeometryShape.circle:
        return 'Circle: A = pi r^2, P = 2 pi r';
      case _GeometryShape.rectangle:
        return 'Rectangle: A = l * w, P = 2(l + w)';
      case _GeometryShape.rightTriangle:
        return 'Right triangle: A = 1/2 * b * h, P = b + h + sqrt(b^2 + h^2)';
    }
  }
}

class _FormulaGraphCard extends StatelessWidget {
  const _FormulaGraphCard({
    required this.expressionText,
    required this.xMin,
    required this.xMax,
    required this.onError,
    required this.onSuccess,
  });

  final String expressionText;
  final double xMin;
  final double xMax;
  final ValueChanged<String> onError;
  final VoidCallback onSuccess;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: CustomPaint(
          painter: _FormulaGraphPainter(
            expressionText: expressionText,
            xMin: xMin,
            xMax: xMax,
            onError: onError,
            onSuccess: onSuccess,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _FormulaGraphPainter extends CustomPainter {
  _FormulaGraphPainter({
    required this.expressionText,
    required this.xMin,
    required this.xMax,
    required this.onError,
    required this.onSuccess,
  });

  final String expressionText;
  final double xMin;
  final double xMax;
  final ValueChanged<String> onError;
  final VoidCallback onSuccess;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1;
    final graphPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerX = _mapX(0, size);
    final centerY = _mapY(0, size);

    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);

    final parser = Parser();
    late Expression expression;
    try {
      expression = parser.parse(expressionText.isEmpty ? '0' : expressionText);
    } catch (_) {
      onError('Invalid formula syntax. Example: sin(x), x^2, x^3 - 2*x');
      return;
    }

    final contextModel = ContextModel();
    final path = Path();
    var started = false;

    double yMin = double.infinity;
    double yMax = double.negativeInfinity;

    final values = <double?>[];
    for (var i = 0; i < size.width.toInt(); i++) {
      final x = xMin + (i / size.width) * (xMax - xMin);
      contextModel.bindVariableName('x', Number(x));
      try {
        final y = expression.evaluate(EvaluationType.REAL, contextModel);
        if (y.isFinite) {
          values.add(y);
          yMin = math.min(yMin, y);
          yMax = math.max(yMax, y);
        } else {
          values.add(null);
        }
      } catch (_) {
        values.add(null);
      }
    }

    if (!yMin.isFinite || !yMax.isFinite || yMin == yMax) {
      onError('Formula could not be evaluated in this x range.');
      return;
    }

    for (var i = 0; i < values.length; i++) {
      final y = values[i];
      if (y == null) {
        started = false;
        continue;
      }
      final px = i.toDouble();
      final py = _mapValue(y, yMin, yMax, size.height);
      if (!started) {
        path.moveTo(px, py);
        started = true;
      } else {
        path.lineTo(px, py);
      }
    }

    canvas.drawPath(path, graphPaint);
    onSuccess();
  }

  double _mapX(double x, Size size) {
    return ((x - xMin) / (xMax - xMin)) * size.width;
  }

  double _mapY(double y, Size size) {
    return size.height * 0.5 - y;
  }

  double _mapValue(double y, double yMin, double yMax, double height) {
    final ratio = (y - yMin) / (yMax - yMin);
    return height - (ratio * height);
  }

  @override
  bool shouldRepaint(covariant _FormulaGraphPainter oldDelegate) {
    return oldDelegate.expressionText != expressionText ||
        oldDelegate.xMin != xMin ||
        oldDelegate.xMax != xMax;
  }
}

class _GeometryPainter extends CustomPainter {
  _GeometryPainter({
    required this.shape,
    required this.a,
    required this.b,
  });

  final _GeometryShape shape;
  final double a;
  final double b;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF0B6E4F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = const Color(0xFF0B6E4F).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    switch (shape) {
      case _GeometryShape.circle:
        final radius = math.min(size.width, size.height) * 0.3;
        final center = Offset(size.width / 2, size.height / 2);
        canvas.drawCircle(center, radius, fill);
        canvas.drawCircle(center, radius, stroke);
        break;
      case _GeometryShape.rectangle:
        final rect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width * 0.65,
          height: size.height * 0.45,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
        break;
      case _GeometryShape.rightTriangle:
        final p1 = Offset(size.width * 0.2, size.height * 0.8);
        final p2 = Offset(size.width * 0.8, size.height * 0.8);
        final p3 = Offset(size.width * 0.2, size.height * 0.25);
        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GeometryPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.a != a || oldDelegate.b != b;
  }
}

enum _GeometryShape {
  circle,
  rectangle,
  rightTriangle,
}
