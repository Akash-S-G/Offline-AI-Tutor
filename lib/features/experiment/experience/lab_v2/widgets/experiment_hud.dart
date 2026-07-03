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
    return Positioned(
      top: 6,
      left: 0,
      right: 0,
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (onExit != null)
              _HudIconButton(
                tooltip: 'Back',
                icon: Icons.arrow_back,
                onPressed: onExit,
              ),
            const Spacer(),
            if (onToggleDeveloper != null)
              _HudIconButton(
                tooltip: 'Debug',
                icon: Icons.bug_report_outlined,
                onPressed: onToggleDeveloper,
              ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _HudIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
