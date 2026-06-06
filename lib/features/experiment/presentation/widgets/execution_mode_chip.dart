import 'package:flutter/material.dart';
import '../../domain/enums/experiment_enums.dart';

class ExecutionModeChip extends StatelessWidget {
  final ExperimentExecutionMode mode;

  const ExecutionModeChip({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    IconData icon;
    String label;

    switch (mode) {
      case ExperimentExecutionMode.sensor:
        chipColor = Colors.blue;
        icon = Icons.sensors;
        label = 'Sensor';
        break;
      case ExperimentExecutionMode.simulation:
        chipColor = Colors.purple;
        icon = Icons.computer;
        label = 'Simulation';
        break;
      case ExperimentExecutionMode.hybrid:
        chipColor = Colors.orange;
        icon = Icons.auto_awesome;
        label = 'Hybrid';
        break;
      case ExperimentExecutionMode.observation:
        chipColor = Colors.grey;
        icon = Icons.visibility;
        label = 'Observation';
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label),
      backgroundColor: chipColor,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      padding: EdgeInsets.zero,
    );
  }
}
