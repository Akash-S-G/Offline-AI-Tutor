import 'package:flutter/material.dart';

import '../../runtime/runtime_world.dart';
import '../../assessment/analytics/assessment_analytics.dart';
import '../../assessment/models/experiment_assessment.dart';
import '../../assessment/models/assessment_result.dart';
import '../../assessment/models/learning_outcome.dart';
import '../../assessment/models/learning_outcome_result.dart';
import '../../assessment/widgets/report_panel.dart';
import '../../guided_runtime/engine/guided_experiment_engine.dart';
import '../../guided_runtime/widgets/experiment_question_panel.dart';
import '../../investigation/comparison/trial_comparison_engine.dart';
import '../../investigation/conclusions/conclusion_engine.dart';
import '../../investigation/trials/experiment_trial_manager.dart';
import '../../investigation/widgets/trial_history_panel.dart';
import '../services/runtime_label_formatter.dart';
import '../lab_v2/widgets/findings_panel.dart';
import 'lab_workspace_analytics.dart';

class LabRightPanel extends StatefulWidget {
  final RuntimeWorld world;
  final VoidCallback onRecordObservation;
  final LabWorkspaceAnalytics analytics;
  final GuidedExperimentEngine? guidedEngine;
  final ExperimentTrialManager? trialManager;
  final TrialComparisonEngine? comparisonEngine;
  final ConclusionEngine? conclusionEngine;
  final ExperimentAssessment? assessment;
  final List<LearningOutcome> learningOutcomes;
  final AssessmentAnalytics? assessmentAnalytics;
  final ValueChanged<AssessmentResult>? onAssessmentComplete;
  final ValueChanged<List<LearningOutcomeResult>>? onOutcomesEvaluated;
  final ValueChanged<String>? onFeedback;
  final int selectedTabIndex;

  const LabRightPanel({
    super.key,
    required this.world,
    required this.onRecordObservation,
    required this.analytics,
    this.guidedEngine,
    this.trialManager,
    this.comparisonEngine,
    this.conclusionEngine,
    this.assessment,
    this.learningOutcomes = const [],
    this.assessmentAnalytics,
    this.onAssessmentComplete,
    this.onOutcomesEvaluated,
    this.onFeedback,
    this.selectedTabIndex = 0,
  });

  @override
  State<LabRightPanel> createState() => _LabRightPanelState();
}

class _LabRightPanelState extends State<LabRightPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  final RuntimeLabelFormatter _formatter = const RuntimeLabelFormatter();

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (_controller.index == 0) widget.analytics.graphViews++;
      });
    _controller.index = widget.selectedTabIndex.clamp(0, 3);
  }

  @override
  void didUpdateWidget(covariant LabRightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTabIndex != widget.selectedTabIndex) {
      _controller.animateTo(widget.selectedTabIndex.clamp(0, 3));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          TabBar(
            controller: _controller,
            isScrollable: true,
            labelColor: const Color(0xFF0F172A),
            tabs: const [
              Tab(text: 'Findings'),
              Tab(text: 'Observations'),
              Tab(text: 'Assessment'),
              Tab(text: 'Report'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: [
                FindingsPanel(
                  world: widget.world,
                  guidedEngine: widget.guidedEngine,
                  trialManager: widget.trialManager,
                  conclusionEngine: widget.conclusionEngine,
                  formatter: _formatter,
                ),
                _NotesTab(
                  world: widget.world,
                  onRecordObservation: widget.onRecordObservation,
                ),
                widget.guidedEngine == null
                    ? const Center(child: Text('No mission questions.'))
                    : ExperimentQuestionPanel(engine: widget.guidedEngine!),
                widget.assessment == null || widget.assessmentAnalytics == null
                    ? const Center(child: Text('Assessment unavailable.'))
                    : ListView(
                        children: [
                          if (widget.trialManager != null &&
                              widget.comparisonEngine != null &&
                              widget.conclusionEngine != null)
                            SizedBox(
                              height: 260,
                              child: TrialHistoryPanel(
                                trialManager: widget.trialManager!,
                                comparisonEngine: widget.comparisonEngine!,
                                conclusionEngine: widget.conclusionEngine!,
                                onFeedback: widget.onFeedback,
                              ),
                            ),
                          SizedBox(
                            height: 480,
                            child: ReportPanel(
                              guidedEngine: widget.guidedEngine,
                              trialManager: widget.trialManager,
                              comparisonEngine: widget.comparisonEngine,
                              conclusionEngine: widget.conclusionEngine,
                              assessment: widget.assessment!,
                              learningOutcomes: widget.learningOutcomes,
                              analytics: widget.assessmentAnalytics!,
                              onAssessmentComplete: widget.onAssessmentComplete,
                              onOutcomesEvaluated: widget.onOutcomesEvaluated,
                              onFeedback: widget.onFeedback,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  final RuntimeWorld world;
  final VoidCallback onRecordObservation;

  const _NotesTab({required this.world, required this.onRecordObservation});

  @override
  Widget build(BuildContext context) {
    final observations = world.observationStore.getObservations();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: onRecordObservation,
            icon: const Icon(Icons.add_task),
            label: const Text('Take Measurement'),
          ),
        ),
        Expanded(
          child: observations.isEmpty
              ? const Center(child: Text('No notes captured yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final observation = observations[index];
                    return ListTile(
                      tileColor: Colors.white,
                      title: Text('Note ${index + 1}'),
                      subtitle: Text('${observation.values}'),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemCount: observations.length,
                ),
        ),
      ],
    );
  }
}
