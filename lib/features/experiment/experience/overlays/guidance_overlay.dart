import 'package:flutter/material.dart';

import '../models/experiment_step.dart';

class GuidanceOverlay extends StatelessWidget {
  final ExperimentStep? currentStep;
  final ExperimentStep? nextStep;

  const GuidanceOverlay({
    super.key,
    required this.currentStep,
    required this.nextStep,
  });

  @override
  Widget build(BuildContext context) {
    final step = currentStep;
    if (step == null) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                nextStep == null
                    ? step.instruction
                    : '${step.instruction} Next: ${nextStep!.title}',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
