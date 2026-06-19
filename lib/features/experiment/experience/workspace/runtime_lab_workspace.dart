import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

import '../../runtime/runtime_event.dart';
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
import '../lab_v2/interactions/experiment_activity_feed.dart';
import '../lab_v2/interactions/insight_card.dart';
import '../lab_v2/stage/experiment_stage.dart';
import '../lab_v2/stage/scene_definition_resolver.dart';
import '../lab_v2/widgets/completion_dialog.dart';
import '../lab_v2/widgets/experiment_hud.dart';
import '../lab_v2/widgets/experiment_intro_overlay.dart';
import '../lab_v2/widgets/floating_lab_sheet.dart';
import '../lab_v2/widgets/fullscreen_lab_mode.dart';
import '../lab_v2/widgets/laboratory_dock.dart';
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

class _RuntimeLabWorkspaceState extends State<RuntimeLabWorkspace>
    with SingleTickerProviderStateMixin {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final Ticker _ticker;
  Duration _lastFrame = Duration.zero;
  bool _showCompletionBanner = false;
  bool _completionDismissed = false;
  bool _showIntro = true;
  int _lastCompletedTasks = 0;
  int _selectedSheetTab = 0;

  @override
  void initState() {
    super.initState();
    widget.analytics.workspaceSessions++;
    _ticker = createTicker(_onFrame)..start();
    _attachGuidedEngine();
    _emitEnvironmentRendered();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showIntro = false);
    });
  }

  @override
  void didUpdateWidget(covariant RuntimeLabWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guidedEngine != widget.guidedEngine) {
      oldWidget.guidedEngine?.removeListener(_onGuidedStateChanged);
      _attachGuidedEngine();
    }
    if (oldWidget.world != widget.world) {
      _lastFrame = Duration.zero;
      _emitEnvironmentRendered();
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _ticker.dispose();
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
                        ExperimentStage(
                          world: widget.world,
                          environmentMode: _environmentMode(),
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
                        VisualGuidanceOverlay(
                          guidedEngine: widget.guidedEngine,
                          hidden: true,
                        ),
                        ExperimentActivityFeed(
                          eventBus: widget.world.eventBus,
                          hidden: true,
                        ),
                        InsightCard(
                          eventBus: widget.world.eventBus,
                          hidden: true,
                        ),
                        LaboratoryDock(
                          onRun: widget.onRun,
                          onPause: widget.onPause,
                          onResume: widget.onResume,
                          onStop: widget.onStop,
                          onReset: widget.onReset,
                          onObserve: () => _openSheetTab(1),
                          onMeasure: _captureMeasurement,
                          onOpenInvestigation: () => _openSheetTab(0),
                          isRunning: widget.isRunning,
                          isPaused: widget.isPaused,
                          isPreparing: widget.isPreparing,
                        ),
                        FloatingLabSheet(
                          hidden: false,
                          controller: _sheetController,
                          bottomInset: 58,
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
                            developerPanel: widget.developerMode ? widget.developerPanel : null,
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
                        ExperimentIntroOverlay(
                          title:
                              widget.guidedEngine?.mission?.title ??
                              widget.experience.title,
                          goal: _introGoal(),
                          bullets: _introBullets(),
                          visible: _showIntro,
                          onSkip: () => setState(() => _showIntro = false),
                        ),
                      ],
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

  void _onFrame(Duration elapsed) {
    if (_lastFrame == Duration.zero) {
      _lastFrame = elapsed;
      return;
    }
    final dt = (elapsed - _lastFrame).inMicroseconds / 1000000;
    _lastFrame = elapsed;
    if (dt <= 0 || dt > 0.1) return;
    widget.world.tick(dt);
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
    final visualEnvironment =
        widget.world.visualizationState?.activeEnvironment.id;
    if (visualEnvironment != null && visualEnvironment.isNotEmpty) {
      return visualEnvironment;
    }
    final metadata = widget.world.metadata;
    return metadata['environment']?.toString() ??
        metadata['environmentMode']?.toString() ??
        metadata['setting']?.toString() ??
        metadata['category']?.toString() ??
        'lab';
  }

  String _introGoal() {
    final scene = const SceneDefinitionResolver().resolve(widget.world);
    final description = widget.world.metadata['description']?.toString();
    if (description != null && description.isNotEmpty) return description;
    return 'Investigate how ${scene.primaryVariable.toLowerCase()} changes ${scene.primaryOutcome.toLowerCase()}.';
  }

  List<String> _introBullets() {
    final scene = const SceneDefinitionResolver().resolve(widget.world);
    final currentTask = widget.guidedEngine?.state.currentTask?.title;
    return [
      'Watch the ${scene.primaryObject.toLowerCase()} in the experiment stage.',
      'Change instruments and look for cause and effect.',
      if (currentTask != null)
        currentTask
      else
        'Collect evidence before making a conclusion.',
    ];
  }

  void _emitEnvironmentRendered() {
    final environment = _environmentMode();
    widget.world.eventBus.emit(
      RuntimeEvent(
        id: 'EnvironmentRendered_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: 'EnvironmentRendered',
        metadata: {'environment': environment},
      ),
    );
  }

  double _estimateVisibleCanvasPercentage(BoxConstraints constraints) {
    final height = constraints.maxHeight;
    final width = constraints.maxWidth;
    if (!height.isFinite || !width.isFinite || height <= 0 || width <= 0) {
      return 0.82;
    }
    const hudHeight = 48.0;
    const dockHeight = 58.0;
    final collapsedSheetHeight = height * 0.05;
    final graphDockArea = width * 0.24 * (height - hudHeight - dockHeight);
    final developerArea = widget.developerMode ? width * height * 0.35 : 0.0;
    final coveredArea =
        (hudHeight + dockHeight + collapsedSheetHeight) * width +
        graphDockArea +
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
    final task = widget.guidedEngine?.state.currentTask;
    final focusTargets =
        widget.world.visualizationState?.activeProfile.focusTargets ?? const [];
    if (task != null) {
      widget.world.eventBus.emit(
        RuntimeEvent(
          id: 'VisualFocusTriggered_${DateTime.now().microsecondsSinceEpoch}',
          timestamp: DateTime.now(),
          type: RuntimeEventType.custom,
          message: 'VisualFocusTriggered',
          metadata: {
            'targetId': focusTargets.isEmpty ? null : focusTargets.first,
            'targetCategory': 'task',
            'reason': task.title,
            'durationMs': 3000,
          },
        ),
      );
    }
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
