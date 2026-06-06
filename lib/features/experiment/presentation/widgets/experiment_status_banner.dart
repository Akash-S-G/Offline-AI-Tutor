import 'package:flutter/material.dart';
import '../../application/orchestrator/experiment_execution_state.dart';

class ExperimentStatusBanner extends StatelessWidget {
  final ExperimentExecutionState state;
  final bool hasWarnings;
  final bool isOfflineSyncing;

  const ExperimentStatusBanner({
    super.key,
    required this.state,
    this.hasWarnings = false,
    this.isOfflineSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String text;

    switch (state) {
      case ExperimentExecutionState.idle:
      case ExperimentExecutionState.preparing:
      case ExperimentExecutionState.analyzing:
      case ExperimentExecutionState.planning:
      case ExperimentExecutionState.starting:
        bgColor = Colors.blue;
        text = 'Initializing...';
        break;
      case ExperimentExecutionState.running:
        bgColor = Colors.green;
        text = 'Running';
        break;
      case ExperimentExecutionState.paused:
        bgColor = Colors.orange;
        text = 'Paused';
        break;
      case ExperimentExecutionState.completed:
        bgColor = Colors.teal;
        text = 'Completed';
        break;
      case ExperimentExecutionState.failed:
        bgColor = Colors.red;
        text = 'Failed';
        break;
      case ExperimentExecutionState.disposed:
        bgColor = Colors.grey;
        text = 'Disposed';
        break;
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (state == ExperimentExecutionState.running)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              Text(
                text.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              if (hasWarnings)
                const Icon(Icons.warning, color: Colors.yellow, size: 16),
              if (hasWarnings) const SizedBox(width: 8),
              if (isOfflineSyncing)
                const Icon(Icons.cloud_off, color: Colors.white70, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
