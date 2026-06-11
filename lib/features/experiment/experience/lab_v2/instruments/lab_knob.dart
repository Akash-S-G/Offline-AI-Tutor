import 'package:flutter/material.dart';

import 'lab_dial.dart';

class LabKnob extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? unit;

  const LabKnob({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return LabDial(
      label: label,
      value: value,
      min: min,
      max: max,
      unit: unit,
      onChanged: onChanged,
    );
  }
}
