import 'package:flutter/material.dart';

import '../engine/guided_experiment_engine.dart';

class CurrentTaskCard extends StatelessWidget {
  final GuidedExperimentEngine engine;

  const CurrentTaskCard({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final task = engine.state.currentTask;
        final completed = engine.state.missionCompleted;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: completed ? const Color(0xFFECFDF5) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: completed
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: completed ? 1.02 : 1,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          completed
                              ? Icons.check_circle
                              : Icons.assignment_outlined,
                          size: 18,
                          color: completed
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF0F766E),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Current Task',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      completed
                          ? 'Mission completed.'
                          : task?.title ?? 'Start the investigation.',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (!completed &&
                        (task?.description.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 5),
                      Text(task!.description),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
