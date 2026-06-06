import 'package:flutter/material.dart';
import '../../runtime/runtime_metrics.dart';

class MeasurementCounterCard extends StatelessWidget {
  final RuntimeMetrics metrics;

  const MeasurementCounterCard({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'SESSION METRICS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCounter('Measurements', metrics.measurementCount.toString(), Colors.blue),
                _buildCounter('Warnings', metrics.warningCount.toString(), Colors.orange),
                _buildCounter('Errors', metrics.errorCount.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Duration: ${metrics.duration.inSeconds}s',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
