import 'package:flutter/material.dart';

import '../models/experiment_step.dart';
import '../models/runtime_experience.dart';
import '../models/runtime_experience_state.dart';

class CurrentTaskCard extends StatelessWidget {
  final RuntimeExperience experience;
  final RuntimeExperienceState state;
  final ExperimentStep? currentStep;

  const CurrentTaskCard({
    super.key,
    required this.experience,
    required this.state,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final step = currentStep;
    final stepNumber = experience.steps.isEmpty
        ? 0
        : state.currentStepIndex.clamp(0, experience.steps.length - 1) + 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Step $stepNumber of ${experience.steps.length}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step?.title ?? 'Ready',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(step?.instruction ?? 'Start the experiment.'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: state.progress / 100,
                backgroundColor: const Color(0xFFE5E7EB),
                color: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 4),
            Text('${state.progress.toStringAsFixed(0)}% complete'),
          ],
        ),
      ),
    );
  }
}
