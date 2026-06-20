import 'package:flutter/material.dart';

import '../../../guided_runtime/engine/guided_experiment_engine.dart';

class FloatingMissionCard extends StatelessWidget {
  final GuidedExperimentEngine? guidedEngine;

  const FloatingMissionCard({
    super.key,
    required this.guidedEngine,
  });

  @override
  Widget build(BuildContext context) {
    if (guidedEngine == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: guidedEngine!,
      builder: (context, _) {
        final state = guidedEngine!.state;
        final currentTask = state.currentTask;
        if (currentTask == null) return const SizedBox.shrink();

        final progress = state.progress;
        final completed = state.completedTasks.length;
        final total = state.mission?.tasks.length ?? 0;

        return Positioned(
          top: 60,
          right: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Task',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '$completed / $total (${(progress * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentTask.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (currentTask.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        currentTask.description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E),
                        ),
                      ),
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
