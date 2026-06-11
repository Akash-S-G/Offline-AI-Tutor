import 'package:flutter/material.dart';

class ExperimentTimeline extends StatelessWidget {
  final Set<String> completedStepIds;
  final int currentIndex;

  const ExperimentTimeline({
    super.key,
    required this.completedStepIds,
    required this.currentIndex,
  });

  static const steps = ['Predict', 'Run', 'Observe', 'Compare', 'Conclude'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 240) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        completedStepIds.contains(steps[i].toLowerCase()) ||
                                i < currentIndex
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: i <= currentIndex
                            ? const Color(0xFF0F766E)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Flexible(child: Text(steps[i])),
                    ],
                  ),
                ),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              _TimelineNode(
                label: steps[i],
                active: i == currentIndex,
                complete:
                    completedStepIds.contains(steps[i].toLowerCase()) ||
                    i < currentIndex,
              ),
              if (i != steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < currentIndex
                        ? const Color(0xFF0F766E)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final String label;
  final bool active;
  final bool complete;

  const _TimelineNode({
    required this.label,
    required this.active,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? const Color(0xFF0F766E)
        : active
        ? const Color(0xFF2563EB)
        : const Color(0xFF94A3B8);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 18 : 14,
          height: active ? 18 : 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: complete
              ? const Icon(Icons.check, size: 11, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
