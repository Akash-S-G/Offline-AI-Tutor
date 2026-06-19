import 'package:flutter/material.dart';

import '../../../guided_runtime/engine/guided_experiment_engine.dart';
import '../../../investigation/trials/experiment_trial_manager.dart';
import '../../../runtime/runtime_world.dart';

class ExperimentHud extends StatelessWidget {
  final String title;
  final Duration elapsed;
  final RuntimeWorld world;
  final GuidedExperimentEngine? guidedEngine;
  final ExperimentTrialManager? trialManager;
  final VoidCallback? onExit;
  final VoidCallback? onToggleDeveloper;

  const ExperimentHud({
    super.key,
    required this.title,
    required this.elapsed,
    required this.world,
    this.guidedEngine,
    this.trialManager,
    this.onExit,
    this.onToggleDeveloper,
  });

  @override
  Widget build(BuildContext context) {
    final progress = guidedEngine?.state.progress ?? 0;
    final completed = guidedEngine?.state.completedTasks.length ?? 0;
    final total = guidedEngine?.mission?.tasks.length ?? 0;
    final missionText = total == 0 ? 'Mission' : 'Mission $completed/$total';
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 48,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xF20F172A),
          border: Border(bottom: BorderSide(color: Color(0xFF334155))),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (onExit != null)
                IconButton(
                  onPressed: onExit,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back',
                  visualDensity: VisualDensity.compact,
                ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                missionText,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              if (onToggleDeveloper != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onToggleDeveloper,
                  icon: const Icon(
                    Icons.bug_report_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Debug',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
