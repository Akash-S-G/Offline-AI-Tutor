import 'package:flutter/material.dart';

import '../../../guided_runtime/engine/guided_experiment_engine.dart';

class ExperimentTimelineV2 extends StatelessWidget {
  final GuidedExperimentEngine? guidedEngine;
  final bool compact;

  const ExperimentTimelineV2({
    super.key,
    required this.guidedEngine,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = guidedEngine?.state;
    final tasks = state?.mission?.tasks ?? const [];
    final labels = tasks.isEmpty
        ? const ['Predict', 'Run', 'Observe', 'Compare', 'Conclude']
        : tasks.take(5).map((task) => task.title).toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < labels.length; i++)
              _TimelineItem(
                label: labels[i],
                complete:
                    state?.completedTasks.contains(
                      tasks.isEmpty ? '' : tasks[i].id,
                    ) ??
                    false,
                active:
                    state?.currentTask?.id ==
                    (tasks.isEmpty ? null : tasks[i].id),
                showLine: i < labels.length - 1,
                compact: compact,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final bool complete;
  final bool active;
  final bool showLine;
  final bool compact;

  const _TimelineItem({
    required this.label,
    required this.complete,
    required this.active,
    required this.showLine,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? const Color(0xFF16A34A)
        : active
        ? const Color(0xFF0F766E)
        : const Color(0xFF94A3B8);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            Icon(
              complete
                  ? Icons.check_circle
                  : active
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: color,
              size: compact ? 16 : 18,
            ),
            if (showLine)
              Container(
                width: 2,
                height: compact ? 14 : 20,
                color: color.withValues(alpha: 0.35),
              ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(width: 7),
          SizedBox(
            width: 110,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
