import 'package:flutter/material.dart';

class MeasurementCaptureFab extends StatelessWidget {
  final VoidCallback onCapture;

  const MeasurementCaptureFab({super.key, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'measurement_capture_fab',
      onPressed: onCapture,
      icon: const Icon(Icons.add_task),
      label: const Text('Take Measurement'),
    );
  }
}
