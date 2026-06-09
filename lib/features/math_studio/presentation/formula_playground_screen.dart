import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/idp_colors.dart';
import 'widgets/formula_visualizers.dart';
import 'widgets/observation_panel.dart';

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
  State<FormulaPlaygroundScreen> createState() => _FormulaPlaygroundScreenState();
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
        return whole == 0 ? 'Percentage = undefined' : 'Percentage = ${(part / whole) * 100}%';
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
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Formula Playground'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDropdown(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
              ),
              child: Text(
                _getExplanation(),
                style: const TextStyle(fontSize: 16, color: Color(0xFF4C1D95)),
              ),
            ),
            const SizedBox(height: 24),
            ..._controllers.keys.map((key) => _buildInputField(key)).toList(),
            const SizedBox(height: 16),
            _buildVisualization(),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: IDPColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: Text(
                  _calculateResult(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ObservationPanel(controller: _notesController),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualization() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IDPColors.border),
      ),
      child: () {
        switch (_selectedFormula) {
          case FormulaType.areaOfCircle:
            return SizedBox(
              height: 150,
              child: CustomPaint(
                painter: CircleVisualizationPainter(_getVal('radius')),
              ),
            );
          case FormulaType.pythagorean:
            return SizedBox(
              height: 150,
              child: CustomPaint(
                painter: PythagoreanPainter(_getVal('a'), _getVal('b')),
              ),
            );
          case FormulaType.simpleInterest:
            return SizedBox(
              height: 150,
              child: CustomPaint(
                painter: InterestPainter(_getVal('principal'), _getVal('rate'), _getVal('time')),
              ),
            );
          case FormulaType.speedDistanceTime:
            return SizedBox(
              height: 100,
              child: CustomPaint(
                painter: SpeedPainter(_getVal('distance'), _getVal('time')),
              ),
            );
          case FormulaType.percentage:
            return SizedBox(
              height: 100,
              child: CustomPaint(
                painter: PercentagePainter(_getVal('part'), _getVal('whole')),
              ),
            );
        }
      }(),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<FormulaType>(
      value: _selectedFormula,
      decoration: InputDecoration(
        labelText: 'Select a Formula to Explore',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: const [
        DropdownMenuItem(value: FormulaType.areaOfCircle, child: Text('Area of Circle')),
        DropdownMenuItem(value: FormulaType.pythagorean, child: Text('Pythagorean Theorem')),
        DropdownMenuItem(value: FormulaType.simpleInterest, child: Text('Simple Interest')),
        DropdownMenuItem(value: FormulaType.speedDistanceTime, child: Text('Speed = Distance / Time')),
        DropdownMenuItem(value: FormulaType.percentage, child: Text('Percentage')),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: _controllers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: key.toUpperCase(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
