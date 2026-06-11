import 'package:flutter/material.dart';

import '../../runtime/runtime_world.dart';
import '../../runtime/simulation/renderers/runtime_canvas_renderer.dart';
import '../../investigation/conclusions/conclusion_generator.dart';
import '../../investigation/engine/investigation_timeline.dart';
import '../../investigation/predictions/prediction_store.dart';
import '../../investigation/trials/experiment_trial_manager.dart';
import '../../investigation/widgets/investigation_workspace.dart';
import '../engine/runtime_experience_engine.dart';
import '../models/experiment_step.dart';
import '../models/runtime_experience.dart';
import '../overlays/guidance_overlay.dart';
import 'current_task_card.dart';
import 'experiment_control_panel.dart';
import 'experiment_objective_card.dart';
import 'graph_workspace.dart';
import 'observation_workspace.dart';

class RuntimeExperienceWorkspace extends StatelessWidget {
  final RuntimeWorld world;
  final RuntimeExperience experience;
  final RuntimeExperienceEngine engine;
  final ValueChanged<String>? onFeedback;
  final VoidCallback onRecordObservation;
  final ExperimentTrialManager? trialManager;
  final PredictionStore? predictionStore;
  final ConclusionGenerator? conclusionGenerator;
  final InvestigationTimeline? investigationTimeline;

  const RuntimeExperienceWorkspace({
    super.key,
    required this.world,
    required this.experience,
    required this.engine,
    required this.onRecordObservation,
    this.onFeedback,
    this.trialManager,
    this.predictionStore,
    this.conclusionGenerator,
    this.investigationTimeline,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final state = engine.state;
        final current = engine.currentStep;
        final next = _nextStep();
        return ColoredBox(
          color: const Color(0xFFF8FAFC),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ExperimentObjectiveCard(experience: experience),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 280,
                        child: SingleChildScrollView(
                          child: ExperimentControlPanel(
                            objectRegistry: world.objects,
                            eventBus: world.eventBus,
                            onFeedback: onFeedback,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              RuntimeCanvasView(canvas: world.simulationCanvas),
                              Positioned(
                                left: 12,
                                right: 12,
                                top: 12,
                                child: GuidanceOverlay(
                                  currentStep: current,
                                  nextStep: next,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                CurrentTaskCard(
                  experience: experience,
                  state: state,
                  currentStep: current,
                ),
                const SizedBox(height: 10),
                if (trialManager != null &&
                    predictionStore != null &&
                    conclusionGenerator != null &&
                    investigationTimeline != null) ...[
                  InvestigationWorkspace(
                    trialManager: trialManager!,
                    predictionStore: predictionStore!,
                    conclusionGenerator: conclusionGenerator!,
                    timeline: investigationTimeline!,
                    onFeedback: onFeedback,
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ObservationWorkspace(
                        store: world.observationStore,
                        onRecordObservation: onRecordObservation,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GraphWorkspace(objectRegistry: world.objects),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ExperimentStep? _nextStep() {
    final completed = engine.state.completedSteps;
    for (final step in experience.steps) {
      if (!completed.contains(step.id) && step.id != engine.currentStep?.id) {
        return step;
      }
    }
    return null;
  }
}
