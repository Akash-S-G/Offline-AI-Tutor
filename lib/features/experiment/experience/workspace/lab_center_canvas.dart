import 'package:flutter/material.dart';

import '../../runtime/runtime_world.dart';
import '../../runtime/simulation/renderers/runtime_canvas_renderer.dart';
import '../../guided_runtime/engine/guided_experiment_engine.dart';
import '../../guided_runtime/widgets/guided_overlay.dart';
import '../../investigation/trials/experiment_trial_manager.dart';
import '../../investigation/widgets/current_trial_banner.dart';
import 'floating_control_dock.dart';
import 'focus_mode_overlay.dart';
import 'measurement_capture_fab.dart';

class LabCenterCanvas extends StatelessWidget {
  final RuntimeWorld world;
  final bool focusMode;
  final VoidCallback onToggleFocus;
  final VoidCallback onRun;
  final VoidCallback onReset;
  final VoidCallback onCaptureMeasurement;
  final VoidCallback? onControlInteraction;
  final GuidedExperimentEngine? guidedEngine;
  final ExperimentTrialManager? trialManager;

  const LabCenterCanvas({
    super.key,
    required this.world,
    required this.focusMode,
    required this.onToggleFocus,
    required this.onRun,
    required this.onReset,
    required this.onCaptureMeasurement,
    this.onControlInteraction,
    this.guidedEngine,
    this.trialManager,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF020617),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.all(focusMode ? 10 : 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(focusMode ? 6 : 14),
              child: RuntimeCanvasView(
                canvas: world.simulationCanvas,
                backgroundColor: const Color(0xFFF8FAFC),
              ),
            ),
          ),
          if (!focusMode && guidedEngine != null)
            Positioned(
              top: 20,
              left: 20,
              child: GuidedOverlay(engine: guidedEngine!),
            ),
          if (!focusMode && trialManager != null)
            Positioned(
              top: 20,
              right: 74,
              child: CurrentTrialBanner(trialManager: trialManager!),
            ),
          if (!focusMode)
            FloatingControlDock(
              objectRegistry: world.objects,
              eventBus: world.eventBus,
              onRun: onRun,
              onReset: onReset,
              onInteraction: onControlInteraction,
            ),
          if (!focusMode)
            Positioned(
              left: 20,
              bottom: 20,
              child: MeasurementCaptureFab(onCapture: onCaptureMeasurement),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton.filledTonal(
              tooltip: focusMode ? 'Exit Focus' : 'Focus Experiment',
              onPressed: onToggleFocus,
              icon: Icon(focusMode ? Icons.fullscreen_exit : Icons.fullscreen),
            ),
          ),
          FocusModeOverlay(enabled: focusMode, onExit: onToggleFocus),
        ],
      ),
    );
  }
}
