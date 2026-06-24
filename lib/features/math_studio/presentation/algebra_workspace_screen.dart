import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/idp_colors.dart';
import 'widgets/observation_panel.dart';
import 'widgets/math_studio_workspace_shell.dart';

enum EquationMode { linear, quadratic }

class AlgebraWorkspaceScreen extends StatefulWidget {
  const AlgebraWorkspaceScreen({super.key});

  @override
  State<AlgebraWorkspaceScreen> createState() => _AlgebraWorkspaceScreenState();
}

class _AlgebraWorkspaceScreenState extends State<AlgebraWorkspaceScreen> {
  EquationMode _mode = EquationMode.linear;

  final TextEditingController _aController = TextEditingController(text: '2');
  final TextEditingController _bController = TextEditingController(text: '3');
  final TextEditingController _cController = TextEditingController(text: '11');
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _aController.addListener(_refreshState);
    _bController.addListener(_refreshState);
    _cController.addListener(_refreshState);
  }

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    _cController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _refreshState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final aParsed = double.tryParse(_aController.text.trim());
    final bParsed = double.tryParse(_bController.text.trim());
    final cParsed = double.tryParse(_cController.text.trim());
    final a = aParsed ?? 2;
    final b = bParsed ?? 3;
    final c = cParsed ?? 11;

    final hasInvalidInput =
        aParsed == null || bParsed == null || cParsed == null;

    final linearSolution = a != 0 ? (c - b) / a : null;
    final discriminant = b * b - 4 * a * c;
    final quadraticCenter = a == 0 ? null : -b / (2 * a);

    return MathStudioWorkspaceShell(
      title: 'Algebra Workspace',
      accentColor: const Color(0xFF6366F1),
      children: [
        const Text(
          'Equation Solver',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: IDPColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Solve linear or quadratic equations with step-by-step explanations.',
          style: TextStyle(color: IDPColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        _buildModeSelector(),
        const SizedBox(height: 20),
        _buildEquationPreview(a, b, c),
        const SizedBox(height: 20),
        _buildInputFields(),
        if (hasInvalidInput)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Invalid inputs detected. Using fallback values for calculation.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),
        _buildSolutionCard(
          a,
          b,
          c,
          linearSolution,
          discriminant,
          quadraticCenter,
        ),
        ObservationPanel(controller: _notesController),
      ],
    );
  }

  Widget _buildModeSelector() {
    return SegmentedButton<EquationMode>(
      segments: const [
        ButtonSegment(
          value: EquationMode.linear,
          label: Text('Linear'),
          icon: Icon(Icons.trending_up_rounded),
        ),
        ButtonSegment(
          value: EquationMode.quadratic,
          label: Text('Quadratic'),
          icon: Icon(Icons.abc_rounded),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (selection) {
        setState(() {
          _mode = selection.first;
        });
      },
    );
  }

  Widget _buildEquationPreview(double a, double b, double c) {
    final equationString = _mode == EquationMode.linear
        ? '${_formatCoefficient(a)}x ${_formatSignedTerm(b)} = ${_formatNumber(c)}'
        : '${_formatCoefficient(a)}x² ${_formatSignedTerm(b)}x ${_formatSignedTerm(c)} = 0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IDPColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          equationString,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Color(0xFF6366F1),
          ),
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final fieldWidth = isCompact
            ? constraints.maxWidth
            : (constraints.maxWidth - 24) / 3;

        final fields = [
          _buildTextField(
            _aController,
            _mode == EquationMode.linear ? 'a (slope)' : 'a (x²)',
          ),
          _buildTextField(
            _bController,
            _mode == EquationMode.linear ? 'b (intercept)' : 'b (x)',
          ),
          _buildTextField(
            _cController,
            _mode == EquationMode.linear ? 'c (result)' : 'c (constant)',
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              fields[0],
              const SizedBox(height: 12),
              fields[1],
              const SizedBox(height: 12),
              fields[2],
            ],
          );
        }

        return Row(
          children:
              fields
                  .map((field) => SizedBox(width: fieldWidth, child: field))
                  .expand((widget) => [widget, const SizedBox(width: 12)])
                  .toList()
                ..removeLast(),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSolutionCard(
    double a,
    double b,
    double c,
    double? linearSolution,
    double discriminant,
    double? quadraticCenter,
  ) {
    final List<String> steps = _mode == EquationMode.linear
        ? _linearSteps(a, b, c, linearSolution)
        : _quadraticSteps(a, b, c, discriminant, quadraticCenter);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IDPColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step-by-step Solution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: IDPColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: IDPColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<String> _linearSteps(double a, double b, double c, double? solution) {
    final moved = c - b;
    return [
      'Given equation: ${_formatCoefficient(a)}x ${_formatSignedTerm(b)} = ${_formatNumber(c)}',
      'Subtract ${_formatNumber(b)} from both sides to isolate the x term:\n${_formatCoefficient(a)}x = ${_formatNumber(c)} ${_formatSignedTerm(-b)}',
      'Simplify:\n${_formatCoefficient(a)}x = ${_formatNumber(moved)}',
      'Divide both sides by ${_formatNumber(a)}:\nx = ${_formatNumber(moved)} / ${_formatNumber(a)}',
      solution == null
          ? 'No unique answer when a = 0.'
          : 'Final Answer: x = ${solution.toStringAsFixed(2)}',
    ];
  }

  List<String> _quadraticSteps(
    double a,
    double b,
    double c,
    double discriminant,
    double? center,
  ) {
    if (a == 0) return ['This is not a quadratic equation because a = 0.'];

    final desc = discriminant < 0
        ? 'Because the discriminant is negative, the roots are complex.'
        : 'Because the discriminant is non-negative, the roots are real.';

    List<String> finalAnswers = [];
    if (discriminant > 0) {
      final sqrtDelta = math.sqrt(discriminant);
      final r1 = (-b + sqrtDelta) / (2 * a);
      final r2 = (-b - sqrtDelta) / (2 * a);
      finalAnswers = [
        'Apply the quadratic formula:\nx = (${_formatNumber(-b)} ± ${sqrtDelta.toStringAsFixed(2)}) / ${_formatNumber(2 * a)}',
        'Final Answer:\nx = ${r1.toStringAsFixed(2)} or x = ${r2.toStringAsFixed(2)}',
      ];
    } else if (discriminant == 0) {
      final r = (-b) / (2 * a);
      finalAnswers = [
        'Apply the quadratic formula:\nx = ${_formatNumber(-b)} / ${_formatNumber(2 * a)}',
        'Final Answer:\nx = ${r.toStringAsFixed(2)}',
      ];
    } else {
      final realPart = center ?? (-b / (2 * a));
      final imaginaryPart = math.sqrt(discriminant.abs()) / (2 * a.abs());
      finalAnswers = [
        'Apply the quadratic formula using i = √(-1):\nx = (${_formatNumber(-b)} ± i${math.sqrt(discriminant.abs()).toStringAsFixed(2)}) / ${_formatNumber(2 * a)}',
        'Final Answer:\nx = ${realPart.toStringAsFixed(2)} ± ${imaginaryPart.toStringAsFixed(2)}i',
      ];
    }

    return [
      'Given quadratic equation: ${_formatCoefficient(a)}x² ${_formatSignedTerm(b)}x ${_formatSignedTerm(c)} = 0',
      'Calculate the discriminant (Δ) using b² - 4ac:\nΔ = ${_formatNumber(b)}² - 4(${_formatNumber(a)})(${_formatNumber(c)}) = ${discriminant.toStringAsFixed(2)}',
      desc,
      ...finalAnswers,
    ];
  }

  String _formatNumber(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  String _formatSignedTerm(double value) {
    final formatted = _formatNumber(value.abs());
    return value < 0 ? '- $formatted' : '+ $formatted';
  }

  String _formatCoefficient(double value) {
    if (value == 1) return '';
    if (value == -1) return '-';
    return _formatNumber(value);
  }
}
