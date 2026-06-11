import 'package:flutter/material.dart';

import '../../../assessment/models/assessment_result.dart';
import '../../../assessment/models/learning_outcome_result.dart';

class CompletionDialog extends StatelessWidget {
  final bool visible;
  final AssessmentResult? assessmentResult;
  final List<LearningOutcomeResult> outcomes;
  final VoidCallback onClose;

  const CompletionDialog({
    super.key,
    required this.visible,
    required this.onClose,
    this.assessmentResult,
    this.outcomes = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final achieved = outcomes
        .where((outcome) => outcome.status == LearningOutcomeStatus.achieved)
        .length;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 28),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFF59E0B),
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mission Complete',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Score: ${assessmentResult?.score.toStringAsFixed(0) ?? '--'}%',
                    ),
                    Text('Outcomes Achieved: $achieved'),
                    const Text('Report Ready'),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: onClose,
                      child: const Text('Continue Lab'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
