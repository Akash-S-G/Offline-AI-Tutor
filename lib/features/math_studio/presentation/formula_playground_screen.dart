import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/idp_colors.dart';
import 'widgets/formula_visualizers.dart';
import 'widgets/observation_panel.dart';
import 'widgets/math_studio_workspace_shell.dart';

enum FormulaType {
  areaOfCircle,
  pythagorean,
  simpleInterest,
  speedDistanceTime,
  percentage,
}

class FormulaPlaygroundScreen extends StatefulWidget {
  const FormulaPlaygroundScreen({super.key});

  @override
  State<FormulaPlaygroundScreen> createState() =>
      _FormulaPlaygroundScreenState();
}

class _FormulaPlaygroundScreenState extends State<FormulaPlaygroundScreen> {
  FormulaType _selectedFormula = FormulaType.areaOfCircle;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();

    switch (_selectedFormula) {
      case FormulaType.areaOfCircle:
        _controllers['radius'] = TextEditingController(text: '5');
        break;
      case FormulaType.pythagorean:
        _controllers['a'] = TextEditingController(text: '3');
        _controllers['b'] = TextEditingController(text: '4');
        break;
      case FormulaType.simpleInterest:
        _controllers['principal'] = TextEditingController(text: '1000');
        _controllers['rate'] = TextEditingController(text: '5');
        _controllers['time'] = TextEditingController(text: '2');
        break;
      case FormulaType.speedDistanceTime:
        _controllers['distance'] = TextEditingController(text: '100');
        _controllers['time'] = TextEditingController(text: '2');
        break;
      case FormulaType.percentage:
        _controllers['part'] = TextEditingController(text: '20');
        _controllers['whole'] = TextEditingController(text: '100');
        break;
    }

    for (final c in _controllers.values) {
      c.addListener(() {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  double _getVal(String key) {
    return double.tryParse(_controllers[key]?.text ?? '0') ?? 0.0;
  }

  String _calculateResult() {
    switch (_selectedFormula) {
      case FormulaType.areaOfCircle:
        final r = _getVal('radius');
        return 'Area = ${math.pi * r * r}';
      case FormulaType.pythagorean:
        final a = _getVal('a');
        final b = _getVal('b');
        return 'c (Hypotenuse) = ${math.sqrt(a * a + b * b)}';
      case FormulaType.simpleInterest:
        final p = _getVal('principal');
        final r = _getVal('rate');
        final t = _getVal('time');
        return 'Interest = ${(p * r * t) / 100}';
      case FormulaType.speedDistanceTime:
        final d = _getVal('distance');
        final t = _getVal('time');
        return t == 0 ? 'Speed = Infinity' : 'Speed = ${d / t}';
      case FormulaType.percentage:
        final part = _getVal('part');
        final whole = _getVal('whole');
        return whole == 0
            ? 'Percentage = undefined'
            : 'Percentage = ${(part / whole) * 100}%';
    }
  }

  String _getExplanation() {
    switch (_selectedFormula) {
      case FormulaType.areaOfCircle:
        return 'The Area of a Circle is the space occupied by the circle in a 2D plane. The formula is A = πr², where r is the radius.';
      case FormulaType.pythagorean:
        return 'The Pythagorean Theorem states that in a right-angled triangle, the square of the hypotenuse side is equal to the sum of squares of the other two sides: a² + b² = c².';
      case FormulaType.simpleInterest:
        return 'Simple Interest is a quick and easy method of calculating the interest charge on a loan. Formula: I = (P × R × T) / 100.';
      case FormulaType.speedDistanceTime:
        return 'Speed tells us how fast an object is moving. Formula: Speed = Distance / Time.';
      case FormulaType.percentage:
        return 'A percentage is a number or ratio expressed as a fraction of 100. Formula: (Part / Whole) × 100.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MathStudioWorkspaceShell(
      title: 'Formula Playground',
      accentColor: IDPColors.tertiary,
      children: [
        _buildDropdown(),
        const SizedBox(height: IDPSpacing.md),
        Container(
          padding: const EdgeInsets.all(IDPSpacing.md),
          decoration: BoxDecoration(
            color: IDPColors.tertiary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(IDPRadius.md),
            border: Border.all(
              color: IDPColors.tertiary.withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            _getExplanation(),
            style: IDPTypography.bodyMedium.copyWith(
              color: IDPColors.tertiary,
            ),
          ),
        ),
        const SizedBox(height: IDPSpacing.md),
        ..._controllers.keys.map(_buildInputField),
        const SizedBox(height: IDPSpacing.sm),
        _buildVisualization(),
        const SizedBox(height: IDPSpacing.md),
        Container(
          padding: const EdgeInsets.all(IDPSpacing.lg),
          decoration: BoxDecoration(
            color: IDPColors.surface,
            borderRadius: BorderRadius.circular(IDPRadius.md),
            border: Border.all(color: IDPColors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: IDPColors.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _calculateResult(),
              style: IDPTypography.h3.copyWith(
                color: IDPColors.tertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: IDPSpacing.md),
        ObservationPanel(controller: _notesController),
      ],
    );
  }

  Widget _buildVisualization() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: IDPColors.surface,
        borderRadius: BorderRadius.circular(IDPRadius.md),
        border: Border.all(color: IDPColors.outlineVariant),
      ),
      child:
          _selectedFormula == FormulaType.speedDistanceTime ||
              _selectedFormula == FormulaType.percentage
          ? AspectRatio(
              aspectRatio: 3.0,
              child: CustomPaint(painter: _buildPainter()),
            )
          : AspectRatio(
              aspectRatio: 1.8,
              child: CustomPaint(painter: _buildPainter()),
            ),
    );
  }

  CustomPainter _buildPainter() {
    switch (_selectedFormula) {
      case FormulaType.areaOfCircle:
        return CircleVisualizationPainter(_getVal('radius'));
      case FormulaType.pythagorean:
        return PythagoreanPainter(_getVal('a'), _getVal('b'));
      case FormulaType.simpleInterest:
        return InterestPainter(
          _getVal('principal'),
          _getVal('rate'),
          _getVal('time'),
        );
      case FormulaType.speedDistanceTime:
        return SpeedPainter(_getVal('distance'), _getVal('time'));
      case FormulaType.percentage:
        return PercentagePainter(_getVal('part'), _getVal('whole'));
    }
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<FormulaType>(
      initialValue: _selectedFormula,
      decoration: InputDecoration(
        labelText: 'Select a Formula to Explore',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(IDPRadius.sm)),
        filled: true,
        fillColor: IDPColors.surface,
      ),
      items: const [
        DropdownMenuItem(
          value: FormulaType.areaOfCircle,
          child: Text('Area of Circle'),
        ),
        DropdownMenuItem(
          value: FormulaType.pythagorean,
          child: Text('Pythagorean Theorem'),
        ),
        DropdownMenuItem(
          value: FormulaType.simpleInterest,
          child: Text('Simple Interest'),
        ),
        DropdownMenuItem(
          value: FormulaType.speedDistanceTime,
          child: Text('Speed = Distance / Time'),
        ),
        DropdownMenuItem(
          value: FormulaType.percentage,
          child: Text('Percentage'),
        ),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedFormula = val;
            _initControllers();
          });
        }
      },
    );
  }

  Widget _buildInputField(String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: IDPSpacing.md),
      child: TextField(
        controller: _controllers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: key.toUpperCase(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(IDPRadius.sm)),
          filled: true,
          fillColor: IDPColors.surface,
        ),
      ),
    );
  }
}
