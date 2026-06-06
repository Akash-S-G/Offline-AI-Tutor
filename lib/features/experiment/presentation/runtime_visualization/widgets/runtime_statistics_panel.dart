import 'package:flutter/material.dart';

class RuntimeStatisticsPanel extends StatelessWidget {
  final int measurementsReceived;
  final int warnings;
  final int errors;
  final int eventsProcessed;
  final Duration runtimeDuration;

  const RuntimeStatisticsPanel({
    super.key,
    required this.measurementsReceived,
    required this.warnings,
    required this.errors,
    required this.eventsProcessed,
    required this.runtimeDuration,
  });

  @override
  Widget build(BuildContext context) {
    final String minutes = runtimeDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds = runtimeDuration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCol('Time', '$minutes:$seconds', Icons.timer, Colors.blue),
            _buildStatCol('Events', '$eventsProcessed', Icons.speed, Colors.purple),
            _buildStatCol('Sensors', '$measurementsReceived', Icons.sensors, Colors.green),
            if (warnings > 0) _buildStatCol('Warn', '$warnings', Icons.warning, Colors.orange),
            if (errors > 0) _buildStatCol('Error', '$errors', Icons.error, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
