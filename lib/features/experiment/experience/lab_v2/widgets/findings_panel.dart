import 'package:flutter/material.dart';

import '../../../guided_runtime/engine/guided_experiment_engine.dart';
import '../../../investigation/conclusions/conclusion_engine.dart';
import '../../../investigation/trials/experiment_trial_manager.dart';
import '../../../runtime/runtime_world.dart';
import '../../services/runtime_label_formatter.dart';

class FindingsPanel extends StatelessWidget {
  final RuntimeWorld world;
  final GuidedExperimentEngine? guidedEngine;
  final ExperimentTrialManager? trialManager;
  final ConclusionEngine? conclusionEngine;
  final RuntimeLabelFormatter formatter;

  const FindingsPanel({
    super.key,
    required this.world,
    this.guidedEngine,
    this.trialManager,
    this.conclusionEngine,
    this.formatter = const RuntimeLabelFormatter(),
  });

  @override
  Widget build(BuildContext context) {
    final observations = world.observationStore.getObservations();
    final sampleCount = world.measurementStore.trackedVariableIds.fold<int>(
      0,
      (count, id) => count + world.measurementStore.sampleCount(id),
    );
    final variables = world.variables.allRuntimeVariables.values.toList();
    final progress = guidedEngine?.state.progress ?? 0;
    final completedTrials = trialManager?.completedTrialCount ?? 0;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _FindingCard(
          icon: Icons.explore_outlined,
          title: 'Investigation',
          value: '${(progress * 100).toStringAsFixed(0)}% complete',
          detail:
              guidedEngine?.state.currentTask?.title ??
              'Explore the setup and collect evidence.',
        ),
        const SizedBox(height: 10),
        _FindingCard(
          icon: Icons.science_outlined,
          title: 'Evidence',
          value: '$sampleCount measurements',
          detail: '${observations.length} observations recorded',
        ),
        const SizedBox(height: 10),
        _FindingCard(
          icon: Icons.timeline_outlined,
          title: 'Trials',
          value: '$completedTrials saved',
          detail: trialManager?.activeTrial == null
              ? 'Start a trial when ready.'
              : 'Trial ${trialManager!.activeTrial!.trialNumber} is running.',
        ),
        const SizedBox(height: 10),
        if (variables.isNotEmpty)
          _ReadingStrip(
            variables: variables
                .take(4)
                .map((variable) {
                  return _ReadingSummary(
                    label: formatter.format(
                      variable.name.isEmpty ? variable.id : variable.name,
                    ),
                    value: variable.value.toString(),
                  );
                })
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _FindingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;

  const _FindingCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0F766E)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingStrip extends StatelessWidget {
  final List<_ReadingSummary> variables;

  const _ReadingStrip({required this.variables});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final variable in variables)
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Text(
                '${variable.label}: ${variable.value}',
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReadingSummary {
  final String label;
  final String value;

  const _ReadingSummary({required this.label, required this.value});
}
