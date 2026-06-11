import 'package:flutter/material.dart';

import '../engine/guided_experiment_engine.dart';

class TaskProgressWidget extends StatelessWidget {
  final GuidedExperimentEngine engine;

  const TaskProgressWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final state = engine.state;
        final total = state.mission?.tasks.length ?? 0;
        final completed = state.completedTasks.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: state.progress,
                color: const Color(0xFF0F766E),
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(state.progress * 100).toStringAsFixed(0)}%  $completed/$total tasks',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        );
      },
    );
  }
}
