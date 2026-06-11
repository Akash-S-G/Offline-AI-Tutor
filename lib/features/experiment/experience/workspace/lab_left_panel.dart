import 'package:flutter/material.dart';

import '../../guided_runtime/engine/guided_experiment_engine.dart';
import '../../guided_runtime/widgets/current_task_card.dart';
import '../../guided_runtime/widgets/mission_card.dart';
import '../../guided_runtime/widgets/task_progress_widget.dart';
import '../../assessment/models/assessment_result.dart';
import '../../assessment/models/learning_outcome_result.dart';
import '../../assessment/widgets/learning_progress_panel.dart';
import '../../investigation/trials/experiment_trial_manager.dart';
import '../../investigation/widgets/investigation_progress_panel.dart';
import '../engine/runtime_experience_engine.dart';
import '../models/runtime_experience.dart';
import 'experiment_timeline.dart';

class LabLeftPanel extends StatelessWidget {
  final RuntimeExperience experience;
  final RuntimeExperienceEngine engine;
  final GuidedExperimentEngine? guidedEngine;
  final ExperimentTrialManager? trialManager;
  final AssessmentResult? assessmentResult;
  final List<LearningOutcomeResult> outcomeResults;

  const LabLeftPanel({
    super.key,
    required this.experience,
    required this.engine,
    this.guidedEngine,
    this.trialManager,
    this.assessmentResult,
    this.outcomeResults = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final current = engine.currentStep;
        return Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  experience.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                if (guidedEngine == null)
                  ..._experienceBlocks(current)
                else
                  ..._guidedBlocks(guidedEngine!),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _experienceBlocks(dynamic current) {
    return [
      _PanelBlock(
        title: 'Goal',
        child: Text(
          experience.objective,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(height: 12),
      _PanelBlock(
        title: 'Progress',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: engine.state.progress / 100,
                color: const Color(0xFF0F766E),
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: 6),
            Text('${engine.state.progress.toStringAsFixed(0)}%'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _PanelBlock(
        title: 'Timeline',
        child: ExperimentTimeline(
          completedStepIds: engine.state.completedSteps,
          currentIndex: _timelineIndex(current?.type.name),
        ),
      ),
      const SizedBox(height: 12),
      _PanelBlock(
        title: 'Current Task',
        child: Text(current?.instruction ?? 'Start the investigation.'),
      ),
    ];
  }

  List<Widget> _guidedBlocks(GuidedExperimentEngine guidedEngine) {
    return [
      MissionCard(engine: guidedEngine),
      const SizedBox(height: 12),
      _PanelBlock(
        title: 'Mission Progress',
        child: TaskProgressWidget(engine: guidedEngine),
      ),
      const SizedBox(height: 12),
      CurrentTaskCard(engine: guidedEngine),
      if (trialManager != null) ...[
        const SizedBox(height: 12),
        _PanelBlock(
          title: 'Investigation Progress',
          child: InvestigationProgressPanel(trialManager: trialManager!),
        ),
      ],
      const SizedBox(height: 12),
      _PanelBlock(
        title: 'Learning Progress',
        child: LearningProgressPanel(
          missionCompleted: guidedEngine.state.missionCompleted,
          assessmentResult: assessmentResult,
          outcomes: outcomeResults,
        ),
      ),
      const SizedBox(height: 12),
      _PanelBlock(
        title: 'Timeline',
        child: AnimatedBuilder(
          animation: guidedEngine,
          builder: (context, _) {
            final state = guidedEngine.state;
            final tasks = state.mission?.tasks ?? const [];
            if (tasks.isEmpty) return const Text('No guided tasks yet.');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tasks.map((task) {
                final active = state.currentTask?.id == task.id;
                final done = state.completedTasks.contains(task.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        done
                            ? Icons.check_circle
                            : active
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 17,
                        color: done
                            ? const Color(0xFF16A34A)
                            : active
                            ? const Color(0xFF0F766E)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: active
                                ? FontWeight.w900
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    ];
  }

  int _timelineIndex(String? stepType) {
    switch (stepType) {
      case 'question':
        return 0;
      case 'interaction':
        return 1;
      case 'observation':
        return 2;
      case 'analysis':
        return 3;
      case 'completion':
        return 4;
      default:
        return 0;
    }
  }
}

class _PanelBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _PanelBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            child,
          ],
        ),
      ),
    );
  }
}
