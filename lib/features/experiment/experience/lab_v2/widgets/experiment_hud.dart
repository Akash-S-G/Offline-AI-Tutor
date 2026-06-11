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
    final task = guidedEngine?.state.currentTask?.title;
    return Positioned(
      top: 8,
      left: 16,
      right: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    if (task != null)
                      Text(
                        task,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF22C55E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
