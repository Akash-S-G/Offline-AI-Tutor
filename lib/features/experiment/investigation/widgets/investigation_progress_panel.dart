import 'package:flutter/material.dart';

import '../trials/experiment_trial_manager.dart';

class InvestigationProgressPanel extends StatelessWidget {
  final ExperimentTrialManager trialManager;
  final int minimumTrials;

  const InvestigationProgressPanel({
    super.key,
    required this.trialManager,
    this.minimumTrials = 2,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trialManager,
      builder: (context, _) {
        final count = trialManager.trialCount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 1; i <= minimumTrials; i++)
              _ProgressRow(label: 'Trial $i', completed: count >= i),
            _ProgressRow(label: 'Compare', completed: count >= 2),
            const _ProgressRow(label: 'Conclusion', completed: false),
          ],
        );
      },
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final bool completed;

  const _ProgressRow({required this.label, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 17,
            color: completed
                ? const Color(0xFF16A34A)
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 7),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
