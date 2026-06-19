import 'package:flutter/material.dart';

import '../../../runtime/runtime_world.dart';
import '../interactions/cause_effect_card.dart';
import '../interactions/cause_effect_overlay.dart';
import '../interactions/spotlight_controller.dart';
import 'experiment_theatre.dart';
import 'live_graph_dock.dart';
import '../../scenes/scene_definition_v3.dart';

class ExperimentStage extends StatelessWidget {
  final RuntimeWorld world;
  final String environmentMode;
  final bool showGraphDock;
  final SceneDefinitionV3 sceneDefinition;

  const ExperimentStage({
    super.key,
    required this.world,
    required this.environmentMode,
    this.showGraphDock = true,
    required this.sceneDefinition,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      top: 48,
      bottom: 62,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF020617)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExperimentTheatre(
              world: world,
              environmentMode: environmentMode,
              sceneDefinition: sceneDefinition,
            ),
            if (showGraphDock) LiveGraphDock(world: world),
            CauseEffectOverlay(eventBus: world.eventBus, hidden: false),
            CauseEffectCard(eventBus: world.eventBus),
            SpotlightController(eventBus: world.eventBus),
          ],
        ),
      ),
    );
  }
}
