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
  final TextEditingController _geometryDepthController = TextEditingController(
    text: '1.5',
  );
  final TextEditingController _algebraAController = TextEditingController(
    text: '2',
  );
  final TextEditingController _algebraBController = TextEditingController(
    text: '3',
  );
  final TextEditingController _algebraCController = TextEditingController(
    text: '11',
  );
  double _xMin = -10;
  double _xMax = 10;
  String? _graphError;

  _GeometryShape _shape = _GeometryShape.circle;
  double _a = 5;
  double _b = 4;
  _EquationMode _equationMode = _EquationMode.linear;

  @override
  void initState() {
    super.initState();
    _formulaController.addListener(_refreshGraph);
    _geometryDepthController.addListener(_refreshState);
    _algebraAController.addListener(_refreshState);
    _algebraBController.addListener(_refreshState);
    _algebraCController.addListener(_refreshState);
  }

  @override
  void dispose() {
    _formulaController.removeListener(_refreshGraph);
    _formulaController.dispose();
    _geometryDepthController.removeListener(_refreshState);
    _geometryDepthController.dispose();
    _algebraAController.removeListener(_refreshState);
    _algebraAController.dispose();
    _algebraBController.removeListener(_refreshState);
    _algebraBController.dispose();
    _algebraCController.removeListener(_refreshState);
    _algebraCController.dispose();
    super.dispose();
  }

  void _refreshGraph() {
    setState(() {
      _graphError = null;
    });
  }

  void _refreshState() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  double get _area {
    switch (_shape) {
      case _GeometryShape.circle:
        return math.pi * _a * _a;
      case _GeometryShape.rectangle:
        return _a * _b;
      case _GeometryShape.rightTriangle:
        return 0.5 * _a * _b;
      case _GeometryShape.square:
        return _a * _a;
      case _GeometryShape.ellipse:
        return math.pi * _a * _b;
      case _GeometryShape.parallelogram:
        return _a * _b;
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
      case _GeometryShape.square:
        return 4 * _a;
      case _GeometryShape.ellipse:
        return math.pi * (3 * (_a + _b) - math.sqrt((3 * _a + _b) * (_a + 3 * _b)));
      case _GeometryShape.parallelogram:
        return 2 * (_a + _b);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Math Studio'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.show_chart_rounded), text: 'Formula 2D'),
              Tab(icon: Icon(Icons.architecture_rounded), text: 'Geometry 2D'),
              Tab(icon: Icon(Icons.calculate_rounded), text: 'Algebra'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFormulaTab(),
            _buildGeometryTab(),
            _buildAlgebraTab(),
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
            onChanged: (_) => setState(() {}),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FormulaChip(label: 'Live update'),
              _FormulaChip(label: 'Grid + axis'),
              _FormulaChip(label: 'Zoomable range'),
            ],
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
    final rawDepth = _geometryDepthController.text.trim();
    final depthParsed = double.tryParse(rawDepth);
    final depth = depthParsed ?? 1.5;
    final depthIsValid = depthParsed != null;
    final volume = _area * depth;

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FormulaChip(label: 'Resizable shape'),
              _FormulaChip(label: 'Area + perimeter'),
              _FormulaChip(label: 'Side notation'),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _shapeSummary(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(_shapeNotation()),
                  const SizedBox(height: 6),
                  Text('Sides: ${_shapeSideCount()}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
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
              DropdownMenuItem(
                value: _GeometryShape.square,
                child: Text('Square'),
              ),
              DropdownMenuItem(
                value: _GeometryShape.ellipse,
                child: Text('Ellipse'),
              ),
              DropdownMenuItem(
                value: _GeometryShape.parallelogram,
                child: Text('Parallelogram'),
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
          Text('Extrusion depth: ${depth.toStringAsFixed(1)}'),
          TextField(
            controller: _geometryDepthController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Depth for volume',
              border: OutlineInputBorder(),
            ),
          ),
          if (!depthIsValid) ...[
            const SizedBox(height: 6),
            const Text(
              'Depth input is invalid. Using fallback value 1.5 for calculations.',
              style: TextStyle(color: Color(0xFFB45309)),
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
                    'Direct answer',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Area = ${_area.toStringAsFixed(2)}'),
                  Text('Perimeter = ${_perimeter.toStringAsFixed(2)}'),
                  Text('Volume (area x depth) = ${volume.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  Text(_formulaDescription()),
                  const SizedBox(height: 6),
                  _StepListCard(
                    title: 'Template Steps',
                    steps: _geometrySteps(depth, volume),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlgebraTab() {
    final aParsed = double.tryParse(_algebraAController.text.trim());
    final bParsed = double.tryParse(_algebraBController.text.trim());
    final cParsed = double.tryParse(_algebraCController.text.trim());
    final a = aParsed ?? 2;
    final b = bParsed ?? 3;
    final c = cParsed ?? 11;
    final hasInvalidInput = aParsed == null || bParsed == null || cParsed == null;
    final linearSolution = a != 0 ? (c - b) / a : null;
    final discriminant = b * b - 4 * a * c;
    final quadraticCenter = a == 0 ? null : -b / (2 * a);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Algebra Balance Simulator',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use free-form coefficients and solve linear or quadratic equations with step templates.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FormulaChip(label: 'Equation builder'),
              _FormulaChip(label: 'Step-by-step solve'),
              _FormulaChip(label: 'Imaginary numbers'),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _equationMode == _EquationMode.linear
                        ? 'Equation: ${_formatCoefficient(a)}x ${_formatSignedTerm(b)} = ${_formatNumber(c)}'
                        : 'Equation: ${_formatCoefficient(a)}x^2 ${_formatSignedTerm(b)}x ${_formatSignedTerm(c)} = 0',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<_EquationMode>(
                    segments: const [
                      ButtonSegment(
                        value: _EquationMode.linear,
                        label: Text('Linear'),
                        icon: Icon(Icons.trending_up_rounded),
                      ),
                      ButtonSegment(
                        value: _EquationMode.quadratic,
                        label: Text('Quadratic'),
                        icon: Icon(Icons.abc_rounded),
                      ),
                    ],
                    selected: {_equationMode},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _equationMode = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCoefficientField(
                    controller: _algebraAController,
                    label: _equationMode == _EquationMode.linear ? 'Coefficient a (x)' : 'Coefficient a (x^2)',
                  ),
                  _buildCoefficientField(
                    controller: _algebraBController,
                    label: _equationMode == _EquationMode.linear ? 'Constant b' : 'Coefficient b (x)',
                  ),
                  _buildCoefficientField(
                    controller: _algebraCController,
                    label: _equationMode == _EquationMode.linear ? 'Right side c' : 'Constant c',
                  ),
                  if (hasInvalidInput)
                    const Text(
                      'One or more inputs are invalid. Temporary fallback values are being used.',
                      style: TextStyle(color: Color(0xFFB45309)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct answer: ${_algebraDirectAnswer(a, b, c, linearSolution, discriminant, quadraticCenter)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  _StepListCard(
                    title: _equationMode == _EquationMode.linear
                        ? 'Linear Template Steps'
                        : 'Quadratic Template Steps',
                    steps: _equationMode == _EquationMode.linear
                        ? _linearSteps(a, b, c, linearSolution)
                        : _quadraticSteps(a, b, c, discriminant, quadraticCenter),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoefficientField({required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  List<String> _linearSteps(double a, double b, double c, double? solution) {
    final equation = '${_formatCoefficient(a)}x ${_formatSignedTerm(b)} = ${_formatNumber(c)}';
    final moved = c - b;
    return [
      'Given equation: ${_formatCoefficient(a)}x ${_formatSignedTerm(b)} = ${_formatNumber(c)}',
      'Substitute template values into ax + b = c.',
      'Move the constant: ${_formatCoefficient(a)}x = ${_formatNumber(c)} ${_formatSignedTerm(-b)} = ${_formatNumber(moved)}',
      'Divide by a: x = ${_formatNumber(moved)} / ${_formatNumber(a)}',
      solution == null
          ? 'No unique answer when a = 0.'
          : 'Answer: x = ${solution.toStringAsFixed(2)}',
      'Template filled: $equation',
    ];
  }

  List<String> _quadraticSteps(
    double a,
    double b,
    double c,
    double discriminant,
    double? center,
  ) {
    final rootDescription = discriminant < 0
        ? 'Because the discriminant is negative, the roots become imaginary. We use i = sqrt(-1).'
        : 'Because the discriminant is non-negative, the roots are real.';
    final answers = _quadraticAnswers(a, b, c, discriminant, center);

    return [
      'Start with ax^2 + bx + c = 0.',
      'Substitute values: ${_formatCoefficient(a)}x^2 ${_formatSignedTerm(b)}x ${_formatSignedTerm(c)} = 0',
      'Discriminant: Δ = b^2 - 4ac = ${_formatNumber(b)}^2 - 4 × ${_formatNumber(a)} × ${_formatNumber(c)} = ${discriminant.toStringAsFixed(2)}',
      rootDescription,
      ...answers,
      'Template: x = (-b ± sqrt(Δ)) / 2a',
    ];
  }

  List<String> _quadraticAnswers(
    double a,
    double b,
    double c,
    double discriminant,
    double? center,
  ) {
    if (a == 0) {
      return ['This is not a quadratic equation because a = 0.'];
    }

    if (discriminant > 0) {
      final sqrtDelta = math.sqrt(discriminant);
      final root1 = (-b + sqrtDelta) / (2 * a);
      final root2 = (-b - sqrtDelta) / (2 * a);
      return [
        'Apply the template: x = (${_formatNumber(-b)} ± ${sqrtDelta.toStringAsFixed(2)}) / ${_formatNumber(2 * a)}',
        'Answer: x = ${root1.toStringAsFixed(2)} and x = ${root2.toStringAsFixed(2)}',
      ];
    }

    if (discriminant == 0) {
      final root = (-b) / (2 * a);
      return [
        'Apply the template: x = ${_formatNumber(-b)} / ${_formatNumber(2 * a)}',
        'Answer: x = ${root.toStringAsFixed(2)}',
      ];
    }

    final imaginaryPart = math.sqrt(discriminant.abs()) / (2 * a.abs());
    final realPart = center ?? (-b / (2 * a));
    return [
      'Apply the template with i: x = (${_formatNumber(-b)} ± i${math.sqrt(discriminant.abs()).toStringAsFixed(2)}) / ${_formatNumber(2 * a)}',
      'Answer: x = ${realPart.toStringAsFixed(2)} ± ${imaginaryPart.toStringAsFixed(2)}i',
      'Imaginary numbers appear when we need the square root of a negative number.',
    ];
  }

  String _shapeSummary() {
    switch (_shape) {
      case _GeometryShape.circle:
        return 'Circle uses one radius and one continuous curved boundary.';
      case _GeometryShape.rectangle:
        return 'Rectangle has 4 sides with opposite sides equal.';
      case _GeometryShape.rightTriangle:
        return 'Right triangle has 3 sides and one 90 degree angle.';
      case _GeometryShape.square:
        return 'Square has 4 equal sides and 4 right angles.';
      case _GeometryShape.ellipse:
        return 'Ellipse uses a major axis and a minor axis.';
      case _GeometryShape.parallelogram:
        return 'Parallelogram has 4 sides with opposite sides parallel.';
    }
  }

  String _shapeNotation() {
    switch (_shape) {
      case _GeometryShape.circle:
        return 'Notation: radius r = ${_a.toStringAsFixed(1)}';
      case _GeometryShape.rectangle:
        return 'Notation: length l = ${_a.toStringAsFixed(1)}, width w = ${_b.toStringAsFixed(1)}, sides = l, w, l, w';
      case _GeometryShape.rightTriangle:
        return 'Notation: side 1 = ${_a.toStringAsFixed(1)}, side 2 = ${_b.toStringAsFixed(1)}, side 3 = sqrt(a^2 + b^2)';
      case _GeometryShape.square:
        return 'Notation: side s = ${_a.toStringAsFixed(1)}, sides = s, s, s, s';
      case _GeometryShape.ellipse:
        return 'Notation: semi-major axis a = ${_a.toStringAsFixed(1)}, semi-minor axis b = ${_b.toStringAsFixed(1)}';
      case _GeometryShape.parallelogram:
        return 'Notation: base = ${_a.toStringAsFixed(1)}, side = ${_b.toStringAsFixed(1)}, height = derived from the preview';
    }
  }

  int _shapeSideCount() {
    switch (_shape) {
      case _GeometryShape.circle:
        return 1;
      case _GeometryShape.rectangle:
        return 4;
      case _GeometryShape.rightTriangle:
        return 3;
      case _GeometryShape.square:
        return 4;
      case _GeometryShape.ellipse:
        return 0;
      case _GeometryShape.parallelogram:
        return 4;
    }
  }

  List<String> _geometrySteps(double depth, double volume) {
    return switch (_shape) {
      _GeometryShape.circle => [
          'Template: Area = pi r^2, Perimeter = 2 pi r, Volume = Area x depth',
          'Substitute radius: r = ${_a.toStringAsFixed(1)}',
          'Area = ${_area.toStringAsFixed(2)}, Perimeter = ${_perimeter.toStringAsFixed(2)}',
          'Volume = ${_area.toStringAsFixed(2)} x ${depth.toStringAsFixed(2)} = ${volume.toStringAsFixed(2)}',
        ],
      _GeometryShape.rectangle => [
          'Template: Area = l x w, Perimeter = 2(l + w), Volume = Area x depth',
          'Substitute: l = ${_a.toStringAsFixed(1)}, w = ${_b.toStringAsFixed(1)}',
          'Area = ${_area.toStringAsFixed(2)}, Perimeter = ${_perimeter.toStringAsFixed(2)}',
          'Volume = ${_area.toStringAsFixed(2)} x ${depth.toStringAsFixed(2)} = ${volume.toStringAsFixed(2)}',
        ],
      _GeometryShape.rightTriangle => [
          'Template: Area = 1/2 x base x height, Perimeter = side1 + side2 + side3, Volume = Area x depth',
          'Substitute: base = ${_a.toStringAsFixed(1)}, height = ${_b.toStringAsFixed(1)}',
          'Area = ${_area.toStringAsFixed(2)}, Perimeter = ${_perimeter.toStringAsFixed(2)}',
          'Volume = ${_area.toStringAsFixed(2)} x ${depth.toStringAsFixed(2)} = ${volume.toStringAsFixed(2)}',
        ],
      _GeometryShape.square => [
          'Template: Area = s^2, Perimeter = 4s, Volume = Area x depth',
          'Substitute: s = ${_a.toStringAsFixed(1)}',
          'Area = ${_area.toStringAsFixed(2)}, Perimeter = ${_perimeter.toStringAsFixed(2)}',
          'Volume = ${_area.toStringAsFixed(2)} x ${depth.toStringAsFixed(2)} = ${volume.toStringAsFixed(2)}',
        ],
      _GeometryShape.ellipse => [
          'Template: Area = piab, Perimeter is approximate, Volume = Area x depth',
          'Substitute: a = ${_a.toStringAsFixed(1)}, b = ${_b.toStringAsFixed(1)}',
          'Area = ${_area.toStringAsFixed(2)}, Perimeter = ${_perimeter.toStringAsFixed(2)}',
          'Volume = ${_area.toStringAsFixed(2)} x ${depth.toStringAsFixed(2)} = ${volume.toStringAsFixed(2)}',
        ],
      _GeometryShape.parallelogram => [
          'Template: Area = base x height, Perimeter = 2(a + b), Volume = Area x depth',
          'Substitute: base = ${_a.toStringAsFixed(1)}, side/height = ${_b.toStringAsFixed(1)}',
          'Area = ${_area.toStringAsFixed(2)}, Perimeter = ${_perimeter.toStringAsFixed(2)}',
          'Volume = ${_area.toStringAsFixed(2)} x ${depth.toStringAsFixed(2)} = ${volume.toStringAsFixed(2)}',
        ],
    };
  }

  String _algebraDirectAnswer(
    double a,
    double b,
    double c,
    double? linearSolution,
    double discriminant,
    double? quadraticCenter,
  ) {
    if (_equationMode == _EquationMode.linear) {
      if (linearSolution == null) {
        return 'No unique solution because a = 0.';
      }
      return 'x = ${linearSolution.toStringAsFixed(2)}';
    }

    if (a == 0) {
      return 'Not a quadratic equation because a = 0.';
    }
    if (discriminant > 0) {
      final sqrtDelta = math.sqrt(discriminant);
      final r1 = (-b + sqrtDelta) / (2 * a);
      final r2 = (-b - sqrtDelta) / (2 * a);
      return 'x = ${r1.toStringAsFixed(2)} and ${r2.toStringAsFixed(2)}';
    }
    if (discriminant == 0) {
      final r = (-b) / (2 * a);
      return 'x = ${r.toStringAsFixed(2)}';
    }
    final realPart = quadraticCenter ?? (-b / (2 * a));
    final imaginaryPart = math.sqrt(discriminant.abs()) / (2 * a.abs());
    return 'x = ${realPart.toStringAsFixed(2)} ± ${imaginaryPart.toStringAsFixed(2)}i';
  }

  String _formulaDescription() {
    switch (_shape) {
      case _GeometryShape.circle:
        return 'Circle: A = pi r^2, P = 2 pi r';
      case _GeometryShape.rectangle:
        return 'Rectangle: A = l * w, P = 2(l + w)';
      case _GeometryShape.rightTriangle:
        return 'Right triangle: A = 1/2 * b * h, P = b + h + sqrt(b^2 + h^2)';
      case _GeometryShape.square:
        return 'Square: A = s^2, P = 4s';
      case _GeometryShape.ellipse:
        return 'Ellipse: A = piab, perimeter is approximated visually';
      case _GeometryShape.parallelogram:
        return 'Parallelogram: A = b * h, P = 2(a + b)';
    }
  }

  String _formatNumber(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  String _formatSignedTerm(double value) {
    final formatted = _formatNumber(value.abs());
    return value < 0 ? '- $formatted' : '+ $formatted';
  }

  String _formatCoefficient(double value) {
    if (value == 1) {
      return '';
    }
    if (value == 0) {
      return '0';
    }
    return _formatNumber(value);
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
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1;
    final graphPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i <= 10; i++) {
      final dx = size.width * (i / 10);
      final dy = size.height * (i / 10);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

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

    final padding = (yMax - yMin).abs() * 0.15;
    yMin -= padding;
    yMax += padding;

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
    _drawCaption(canvas, size, expressionText.isEmpty ? 'f(x) = 0' : expressionText);
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

  void _drawCaption(Canvas canvas, Size size, String title) {
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 12);
    painter.paint(canvas, const Offset(6, 6));
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
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    final stroke = Paint()
      ..color = const Color(0xFF0B6E4F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = const Color(0xFF0B6E4F).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (var i = 0; i <= 8; i++) {
      final dx = size.width * (i / 8);
      final dy = size.height * (i / 8);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    switch (shape) {
      case _GeometryShape.circle:
        final radius = math.min(size.width, size.height) * (0.12 + (a / 40));
        final center = Offset(size.width / 2, size.height / 2);
        canvas.drawCircle(center, radius, fill);
        canvas.drawCircle(center, radius, stroke);
        _paintLabel(canvas, 'r=${a.toStringAsFixed(1)}', center.translate(0, radius + 16));
        break;
      case _GeometryShape.rectangle:
        final rectWidth = (size.width * 0.18 + a * 5).clamp(60.0, size.width * 0.8);
        final rectHeight = (size.height * 0.12 + b * 5).clamp(50.0, size.height * 0.7);
        final rect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: rectWidth,
          height: rectHeight,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
        _paintLabel(canvas, 'l=${a.toStringAsFixed(1)}', Offset(rect.center.dx, rect.top - 14));
        _paintLabel(canvas, 'w=${b.toStringAsFixed(1)}', Offset(rect.right + 18, rect.center.dy));
        break;
      case _GeometryShape.rightTriangle:
        final base = (size.width * 0.16 + a * 5).clamp(60.0, size.width * 0.78);
        final height = (size.height * 0.16 + b * 5).clamp(50.0, size.height * 0.7);
        final p1 = Offset(size.width * 0.16, size.height * 0.82);
        final p2 = Offset(size.width * 0.16 + base, size.height * 0.82);
        final p3 = Offset(size.width * 0.16, size.height * 0.82 - height);
        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(p1.dx - 10, p3.dy - 10, 16, 16),
            const Radius.circular(2),
          ),
          stroke,
        );
        _paintLabel(canvas, 'a=${a.toStringAsFixed(1)}', Offset((p1.dx + p2.dx) / 2, p1.dy + 16));
        _paintLabel(canvas, 'b=${b.toStringAsFixed(1)}', Offset(p1.dx - 16, (p1.dy + p3.dy) / 2));
        _paintLabel(canvas, 'c=${math.sqrt(a * a + b * b).toStringAsFixed(1)}', Offset((p2.dx + p3.dx) / 2 + 18, (p2.dy + p3.dy) / 2 - 8));
        break;
      case _GeometryShape.square:
        final side = (math.min(size.width, size.height) * (0.2 + a / 40)).clamp(60.0, math.min(size.width, size.height) * 0.8);
        final rect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: side,
          height: side,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
        _paintLabel(canvas, 's=${a.toStringAsFixed(1)}', Offset(rect.center.dx, rect.top - 14));
        _paintLabel(canvas, 's', Offset(rect.right + 14, rect.center.dy - 10));
        break;
      case _GeometryShape.ellipse:
        final rx = (size.width * 0.12 + a * 4).clamp(50.0, size.width * 0.42);
        final ry = (size.height * 0.08 + b * 4).clamp(40.0, size.height * 0.38);
        final rect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: rx * 2,
          height: ry * 2,
        );
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, stroke);
        _paintLabel(canvas, 'a=${a.toStringAsFixed(1)}', Offset(rect.center.dx, rect.top - 14));
        _paintLabel(canvas, 'b=${b.toStringAsFixed(1)}', Offset(rect.right + 16, rect.center.dy));
        break;
      case _GeometryShape.parallelogram:
        final width = (size.width * 0.22 + a * 4).clamp(70.0, size.width * 0.8);
        final height = (size.height * 0.14 + b * 4).clamp(50.0, size.height * 0.7);
        final skew = math.min(48.0, a * 3);
        final baseY = size.height * 0.75;
        final left = size.width * 0.22;
        final path = Path()
          ..moveTo(left + skew, baseY - height)
          ..lineTo(left + skew + width, baseY - height)
          ..lineTo(left + width, baseY)
          ..lineTo(left, baseY)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        _paintLabel(canvas, 'base', Offset(left + width / 2, baseY + 16));
        _paintLabel(canvas, 'side', Offset(left + skew + width + 18, baseY - height / 2));
        break;
    }
  }

  void _paintLabel(Canvas canvas, String text, Offset position) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position - Offset(painter.width / 2, painter.height / 2));
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
  square,
  ellipse,
  parallelogram,
}

enum _EquationMode {
  linear,
  quadratic,
}

class _FormulaChip extends StatelessWidget {
  const _FormulaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: const Color(0xFFE0F2FE),
    );
  }
}

class _StepListCard extends StatelessWidget {
  const _StepListCard({
    required this.title,
    required this.steps,
  });

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...List.generate(
            steps.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${index + 1}. ${steps[index]}'),
            ),
          ),
        ],
      ),
    );
  }
}
