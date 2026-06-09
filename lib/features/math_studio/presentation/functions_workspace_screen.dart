import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart' hide Stack;

import '../../../core/theme/idp_colors.dart';
import '../domain/challenge.dart';
import '../domain/saved_exploration.dart';
import '../application/exploration_repository.dart';
import 'widgets/challenge_card.dart';
import 'widgets/concept_card.dart';
import 'widgets/observation_panel.dart';

class FunctionLabScreen extends StatefulWidget {
  final String? initialFormula;
  final String? discoveryPrompt;
  final MathChallenge? challenge;

  const FunctionLabScreen({
    super.key, 
    this.initialFormula, 
    this.discoveryPrompt,
    this.challenge,
  });

  @override
  State<FunctionLabScreen> createState() => _FunctionLabScreenState();
}

class _FunctionLabScreenState extends State<FunctionLabScreen> {
  late final TextEditingController _formulaController;
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _formulaController = TextEditingController(text: widget.initialFormula ?? 'a*x^2 + b*x + c');
    _formulaController.addListener(_onFormulaChanged);
    _onFormulaChanged(); // initial detection
  }
  
  // Auto-detected variables mapping to slider values
  final Map<String, double> _variables = {'a': 1.0, 'b': 0.0, 'c': 0.0};
  
  double _xMin = -10;
  double _xMax = 10;
  String? _graphError;



  @override
  void dispose() {
    _formulaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFormulaChanged() {
    final formula = _formulaController.text;
    
    // Simple regex to find single letter variables, ignoring 'x' and ignoring math functions
    // e.g. ignoring sin, cos, tan, log, exp, sqrt, abs, pi, e
    final ignoreWords = ['sin', 'cos', 'tan', 'log', 'exp', 'sqrt', 'abs', 'pi', 'e', 'x'];
    
    final matches = RegExp(r'[a-zA-Z]+').allMatches(formula);
    final Set<String> foundVars = {};
    
    for (final m in matches) {
      final word = m.group(0)!;
      if (!ignoreWords.contains(word)) {
        foundVars.add(word);
      }
    }

    setState(() {
      _graphError = null;
      // Remove variables that no longer exist
      _variables.removeWhere((key, _) => !foundVars.contains(key));
      // Add new variables with default value 1.0
      for (final v in foundVars) {
        if (!_variables.containsKey(v)) {
          _variables[v] = 1.0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Functions Workspace'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: () async {
              final repo = await ExplorationRepository.create();
              await repo.saveExploration(SavedExploration.create(
                title: 'Function Snapshot: ${_formulaController.text}',
                type: ExplorationType.functions,
                data: {
                  'formula': _formulaController.text,
                  'variables': _variables,
                  'notes': _notesController.text,
                },
              ));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workspace saved!')));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.discoveryPrompt != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFD97706).withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFB45309)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.discoveryPrompt!,
                      style: const TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.challenge != null)
            ChallengeCard(
              challenge: widget.challenge!,
              isCompleted: widget.challenge!.verifier(_variables),
            ),
          const ConceptCard(
            title: 'Mathematical Functions',
            description: 'A function relates an input to an output. It is like a machine that has an input and an output, and the output is related somehow to the input.',
            example: 'The trajectory of a thrown ball is a parabola, modeled by a quadratic function taking time as input and height as output.',
            icon: Icons.functions_rounded,
            color: Color(0xFFD97706),
          ),
          _buildFormulaInput(),
          if (_variables.isNotEmpty) _buildSliders(),
          Expanded(
            child: _buildGraphArea(),
          ),
          ObservationPanel(controller: _notesController),
        ],
      ),
    );
  }

  Widget _buildFormulaInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _formulaController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'f(x) =',
              prefixIcon: const Icon(Icons.functions_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: IDPColors.background,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliders() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _variables.keys.map((varName) {
          return Row(
            children: [
              Text(
                '$varName = ${_variables[varName]!.toStringAsFixed(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Expanded(
                child: Slider(
                  min: -10,
                  max: 10,
                  value: _variables[varName]!,
                  activeColor: const Color(0xFFD97706),
                  onChanged: (val) {
                    setState(() {
                      _variables[varName] = val;
                    });
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGraphArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IDPColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox.expand(
              child: CustomPaint(
                painter: _GraphPainter(
                  formula: _formulaController.text,
                  variables: _variables,
                  xMin: _xMin,
                  xMax: _xMax,
                  onError: (err) {
                    if (_graphError != err) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _graphError = err);
                      });
                    }
                  },
                  onSuccess: () {
                    if (_graphError != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _graphError = null);
                      });
                    }
                  },
                ),
              ),
            ),
            if (_graphError != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _graphError!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.zoom_in),
                    onPressed: () => setState(() {
                      _xMin += 1;
                      _xMax -= 1;
                      if (_xMax <= _xMin) {
                        _xMin -= 1;
                        _xMax += 1;
                      }
                    }),
                  ),
                  const SizedBox(height: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.zoom_out),
                    onPressed: () => setState(() {
                      _xMin -= 1;
                      _xMax += 1;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final String formula;
  final Map<String, double> variables;
  final double xMin;
  final double xMax;
  final Function(String) onError;
  final VoidCallback onSuccess;

  _GraphPainter({
    required this.formula,
    required this.variables,
    required this.xMin,
    required this.xMax,
    required this.onError,
    required this.onSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Grid
    final gridPaint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1;
    final axisPaint = Paint()..color = const Color(0xFF64748B)..strokeWidth = 2;

    // Draw grid lines (10 segments)
    for (int i = 0; i <= 10; i++) {
      final dx = size.width * (i / 10);
      final dy = size.height * (i / 10);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    // Attempt to evaluate expression
    if (formula.trim().isEmpty) return;

    Expression exp;
    try {
      Parser p = Parser();
      exp = p.parse(formula);
    } catch (e) {
      onError("Invalid Formula Syntax");
      return;
    }

    ContextModel cm = ContextModel();
    for (final v in variables.entries) {
      cm.bindVariableName(v.key, Number(v.value));
    }

    List<double?> yValues = [];
    double yMinBound = double.infinity;
    double yMaxBound = double.negativeInfinity;

    for (int i = 0; i <= size.width.toInt(); i++) {
      double x = xMin + (i / size.width) * (xMax - xMin);
      cm.bindVariableName('x', Number(x));
      try {
        double y = exp.evaluate(EvaluationType.REAL, cm);
        if (y.isFinite) {
          yValues.add(y);
          if (y < yMinBound) yMinBound = y;
          if (y > yMaxBound) yMaxBound = y;
        } else {
          yValues.add(null);
        }
      } catch (e) {
        yValues.add(null);
      }
    }

    if (yMinBound == double.infinity || yMaxBound == double.negativeInfinity) {
      onError("Could not evaluate over this range");
      return;
    }

    // Add padding to Y bounds
    double padding = (yMaxBound - yMinBound) * 0.1;
    if (padding == 0) padding = 1.0;
    yMinBound -= padding;
    yMaxBound += padding;

    // Draw X and Y Axes if visible
    if (0 >= xMin && 0 <= xMax) {
      double xAxisPos = ((0 - xMin) / (xMax - xMin)) * size.width;
      canvas.drawLine(Offset(xAxisPos, 0), Offset(xAxisPos, size.height), axisPaint);
    }
    if (0 >= yMinBound && 0 <= yMaxBound) {
      double yRatio = (0 - yMinBound) / (yMaxBound - yMinBound);
      double yAxisPos = size.height - (yRatio * size.height);
      canvas.drawLine(Offset(0, yAxisPos), Offset(size.width, yAxisPos), axisPaint);
    }

    // Draw Function Path
    final pathPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    bool isFirst = true;

    for (int i = 0; i < yValues.length; i++) {
      if (yValues[i] == null) {
        isFirst = true;
        continue;
      }
      double px = i.toDouble();
      double yRatio = (yValues[i]! - yMinBound) / (yMaxBound - yMinBound);
      double py = size.height - (yRatio * size.height);

      if (isFirst) {
        path.moveTo(px, py);
        isFirst = false;
      } else {
        path.lineTo(px, py);
      }
    }

    canvas.drawPath(path, pathPaint);
    onSuccess();
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.formula != formula ||
        oldDelegate.xMin != xMin ||
        oldDelegate.xMax != xMax ||
        oldDelegate.variables.toString() != variables.toString();
  }
}
