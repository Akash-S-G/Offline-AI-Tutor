import 'package:flutter/material.dart';

import '../models/assessment_result.dart';
import '../models/learning_outcome_result.dart';

class LearningProgressPanel extends StatelessWidget {
  final bool missionCompleted;
  final AssessmentResult? assessmentResult;
  final List<LearningOutcomeResult> outcomes;

  const LearningProgressPanel({
    super.key,
    required this.missionCompleted,
    this.assessmentResult,
    this.outcomes = const [],
  });

  @override
  Widget build(BuildContext context) {
    final outcomeAchieved = outcomes.any(
      (outcome) => outcome.status == LearningOutcomeStatus.achieved,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row(label: 'Mission Complete', done: missionCompleted),
        _Row(label: 'Assessment Complete', done: assessmentResult != null),
        _Row(label: 'Outcome Achieved', done: outcomeAchieved),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final bool done;

  const _Row({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 17,
            color: done ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 7),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
