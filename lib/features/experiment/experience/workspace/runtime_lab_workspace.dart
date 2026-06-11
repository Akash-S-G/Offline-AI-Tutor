import 'package:flutter/material.dart';

import '../../runtime/simulation/renderers/runtime_canvas_renderer.dart';
import '../../runtime/runtime_world.dart';
import '../../guided_runtime/engine/guided_experiment_engine.dart';
import '../../guided_runtime/widgets/task_completion_banner.dart';
import '../../assessment/analytics/assessment_analytics.dart';
import '../../assessment/models/assessment_result.dart';
import '../../assessment/models/experiment_assessment.dart';
import '../../assessment/models/learning_outcome.dart';
import '../../assessment/models/learning_outcome_result.dart';
import '../../investigation/comparison/trial_comparison_engine.dart';
import '../../investigation/conclusions/conclusion_engine.dart';
import '../../investigation/trials/experiment_trial_manager.dart';
import '../engine/runtime_experience_engine.dart';
import '../models/runtime_experience.dart';
import '../lab_v2/interactions/cause_effect_overlay.dart';
import '../lab_v2/interactions/experiment_activity_feed.dart';
import '../lab_v2/interactions/experiment_narrator.dart';
import '../lab_v2/interactions/insight_card.dart';
import '../lab_v2/interactions/journey_progress.dart';
import '../lab_v2/interactions/simulation_environment.dart';
import '../lab_v2/widgets/completion_dialog.dart';
import '../lab_v2/widgets/experiment_hud.dart';
import '../lab_v2/widgets/floating_lab_sheet.dart';
import '../lab_v2/widgets/fullscreen_lab_mode.dart';
import '../lab_v2/widgets/instrument_controls.dart';
import '../lab_v2/widgets/visual_guidance_overlay.dart';
import 'lab_right_panel.dart';
import 'lab_workspace_analytics.dart';

class RuntimeLabWorkspace extends StatefulWidget {
  final RuntimeWorld world;
  final RuntimeExperience experience;
  final RuntimeExperienceEngine engine;
  final VoidCallback onRecordObservation;
  final VoidCallback onRun;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback onReset;
  final VoidCallback? onExit;
  final VoidCallback? onToggleDeveloper;
  final ValueChanged<String>? onFeedback;
  final LabWorkspaceAnalytics analytics;
  final GuidedExperimentEngine? guidedEngine;
  final ExperimentTrialManager? trialManager;
  final TrialComparisonEngine? comparisonEngine;
  final ConclusionEngine? conclusionEngine;
  final ExperimentAssessment? assessment;
  final List<LearningOutcome> learningOutcomes;
  final AssessmentAnalytics? assessmentAnalytics;
  final AssessmentResult? assessmentResult;
  final List<LearningOutcomeResult> outcomeResults;
  final ValueChanged<AssessmentResult>? onAssessmentComplete;
  final ValueChanged<List<LearningOutcomeResult>>? onOutcomesEvaluated;
  final bool isRunning;
  final bool isPaused;
  final bool isPreparing;
  final bool developerMode;
  final Widget? developerPanel;

  const RuntimeLabWorkspace({
    super.key,
    required this.world,
    required this.experience,
    required this.engine,
    required this.onRecordObservation,
    required this.onRun,
    this.onPause,
    this.onResume,
    this.onStop,
    required this.onReset,
    required this.analytics,
    this.onExit,
    this.onToggleDeveloper,
    this.onFeedback,
    this.guidedEngine,
    this.trialManager,
    this.comparisonEngine,
    this.conclusionEngine,
    this.assessment,
    this.learningOutcomes = const [],
    this.assessmentAnalytics,
    this.assessmentResult,
    this.outcomeResults = const [],
    this.onAssessmentComplete,
    this.onOutcomesEvaluated,
    this.isRunning = false,
    this.isPaused = false,
    this.isPreparing = false,
    this.developerMode = false,
    this.developerPanel,
  });

  @override
  State<RuntimeLabWorkspace> createState() => _RuntimeLabWorkspaceState();
}

class _RuntimeLabWorkspaceState extends State<RuntimeLabWorkspace> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _showCompletionBanner = false;
  bool _completionDismissed = false;
  int _lastCompletedTasks = 0;
  int _selectedSheetTab = 0;

  @override
  void initState() {
    super.initState();
    widget.analytics.workspaceSessions++;
    _attachGuidedEngine();
  }

  @override
  void didUpdateWidget(covariant RuntimeLabWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guidedEngine != widget.guidedEngine) {
      oldWidget.guidedEngine?.removeListener(_onGuidedStateChanged);
      _attachGuidedEngine();
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    widget.guidedEngine?.removeListener(_onGuidedStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return const _RotateDeviceScreen();
        }
        final elapsed = Duration(
          milliseconds: (widget.world.clock.elapsedTime * 1000).round(),
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            widget.analytics.visibleCanvasPercentage =
                _estimateVisibleCanvasPercentage(constraints);
            return FullscreenLabMode(
              enabled: true,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: const Color(0xFF020617),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SimulationEnvironment(mode: _environmentMode()),
                              RuntimeCanvasView(
                                canvas: widget.world.simulationCanvas,
                                backgroundColor: Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                        ExperimentHud(
                          title:
                              widget.guidedEngine?.mission?.title ??
                              widget.experience.title,
                          elapsed: elapsed,
                          world: widget.world,
                          guidedEngine: widget.guidedEngine,
                          trialManager: widget.trialManager,
                          onExit: widget.onExit,
                          onToggleDeveloper: widget.onToggleDeveloper,
                        ),
                        Positioned(
                          left: 16,
                          top: 60,
                          child: JourneyProgress(
                            guidedEngine: widget.guidedEngine,
                            compact: false,
                          ),
                        ),
                        ExperimentNarrator(
                          eventBus: widget.world.eventBus,
                          guidedEngine: widget.guidedEngine,
                          hidden: false,
                        ),
                        VisualGuidanceOverlay(
                          guidedEngine: widget.guidedEngine,
                          hidden: true,
                        ),
                        CauseEffectOverlay(
                          eventBus: widget.world.eventBus,
                          hidden: false,
                        ),
                        ExperimentActivityFeed(
                          eventBus: widget.world.eventBus,
                          hidden: true,
                        ),
                        InsightCard(
                          eventBus: widget.world.eventBus,
                          hidden: true,
                        ),
                        _buildToolCluster(),
                        InstrumentControls(
                          objectRegistry: widget.world.objects,
                          eventBus: widget.world.eventBus,
                          onRun: widget.onRun,
                          onPause: widget.onPause,
                          onResume: widget.onResume,
                          onStop: widget.onStop,
                          onRecordObservation: _captureMeasurement,
                          onReset: widget.onReset,
                          compact: true,
                          isRunning: widget.isRunning,
                          isPaused: widget.isPaused,
                          isPreparing: widget.isPreparing,
                          onInteraction: () =>
                              widget.analytics.controlInteractions++,
                        ),
                        FloatingLabSheet(
                          hidden: false,
                          controller: _sheetController,
                          child: LabRightPanel(
                            world: widget.world,
                            onRecordObservation: _captureMeasurement,
                            analytics: widget.analytics,
                            guidedEngine: widget.guidedEngine,
                            trialManager: widget.trialManager,
                            comparisonEngine: widget.comparisonEngine,
                            conclusionEngine: widget.conclusionEngine,
                            assessment: widget.assessment,
                            learningOutcomes: widget.learningOutcomes,
                            assessmentAnalytics: widget.assessmentAnalytics,
                            onAssessmentComplete: widget.onAssessmentComplete,
                            onOutcomesEvaluated: widget.onOutcomesEvaluated,
                            onFeedback: widget.onFeedback,
                            selectedTabIndex: _selectedSheetTab,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TaskCompletionBanner(
                              visible: _showCompletionBanner,
                            ),
                          ),
                        ),
                        CompletionDialog(
                          visible:
                              (widget.guidedEngine?.state.missionCompleted ??
                                  false) &&
                              !_completionDismissed,
                          assessmentResult: widget.assessmentResult,
                          outcomes: widget.outcomeResults,
                          onClose: () {
                            setState(() => _completionDismissed = true);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (widget.developerMode && widget.developerPanel != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.35,
                        heightFactor: 1,
                        child: widget.developerPanel!,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _captureMeasurement() {
    widget.analytics.measurementCaptures++;
    widget.onRecordObservation();
    widget.onFeedback?.call('Measurement Saved');
  }

  Widget _buildToolCluster() {
    return Positioned(
      left: 18,
      bottom: 38,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF334155)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toolButton(
                icon: Icons.show_chart,
                tooltip: 'Graphs',
                tabIndex: 1,
              ),
              _toolButton(
                icon: Icons.note_alt_outlined,
                tooltip: 'Notes',
                tabIndex: 2,
              ),
              _toolButton(
                icon: Icons.science_outlined,
                tooltip: 'Trials',
                tabIndex: 4,
              ),
              _toolButton(
                icon: Icons.assignment_outlined,
                tooltip: 'Assessment',
                tabIndex: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String tooltip,
    required int tabIndex,
  }) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () => _openSheetTab(tabIndex),
      icon: Icon(icon, color: Colors.white, size: 20),
    );
  }

  void _openSheetTab(int tabIndex) {
    setState(() => _selectedSheetTab = tabIndex);
    if (!_sheetController.isAttached) return;
    _sheetController.animateTo(
      0.42,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _attachGuidedEngine() {
    final engine = widget.guidedEngine;
    if (engine == null) return;
    _lastCompletedTasks = engine.state.completedTasks.length;
    engine.addListener(_onGuidedStateChanged);
  }

  String _environmentMode() {
    final metadata = widget.world.metadata;
    return metadata['environment']?.toString() ??
        metadata['environmentMode']?.toString() ??
        metadata['setting']?.toString() ??
        metadata['category']?.toString() ??
        'lab';
  }

  double _estimateVisibleCanvasPercentage(BoxConstraints constraints) {
    final height = constraints.maxHeight;
    final width = constraints.maxWidth;
    if (!height.isFinite || !width.isFinite || height <= 0 || width <= 0) {
      return 0.82;
    }
    const hudHeight = 52.0;
    final collapsedSheetHeight = height * 0.05;
    final controlDockArea = 320.0.clamp(0, width) * 56;
    final toolClusterArea = 210.0.clamp(0, width) * 50;
    final developerArea = widget.developerMode ? width * height * 0.35 : 0.0;
    final coveredArea =
        (hudHeight + collapsedSheetHeight) * width +
        controlDockArea +
        toolClusterArea +
        developerArea;
    final visible = 1 - (coveredArea / (width * height));
    return visible.clamp(0, 1).toDouble();
  }

  void _onGuidedStateChanged() {
    final completed = widget.guidedEngine?.state.completedTasks.length ?? 0;
    if (completed <= _lastCompletedTasks) return;
    _lastCompletedTasks = completed;
    if (!mounted) return;
    setState(() => _showCompletionBanner = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCompletionBanner = false);
    });
  }
}

class _RotateDeviceScreen extends StatelessWidget {
  const _RotateDeviceScreen();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.screen_rotation, color: Colors.white, size: 52),
            SizedBox(height: 16),
            Text(
              'Rotate device for lab workspace',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
