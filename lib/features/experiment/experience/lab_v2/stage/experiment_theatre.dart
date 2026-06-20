import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../runtime/runtime_world.dart';
import '../../../runtime/simulation/renderers/runtime_canvas_renderer.dart';
import '../../scenes/scene_definition_v3.dart';
import '../../scenes/scene_themes.dart';
import '../interactions/scene_controls_overlay.dart';
import '../../../immersive_runtime/idle_animation_controller.dart';
import '../../../immersive_runtime/visual_response_controller.dart';
import '../../../immersive_runtime/scene_effect_controller.dart';
import '../../../immersive_runtime/interaction_feedback_controller.dart';
class ExperimentTheatre extends StatelessWidget {
  final RuntimeWorld world;
  final String environmentMode;
  final SceneDefinitionV3 sceneDefinition;

  const ExperimentTheatre({
    super.key,
    required this.world,
    required this.environmentMode,
    required this.sceneDefinition,
  });

  @override
  Widget build(BuildContext context) {
    final theme = SceneTheme.getById(sceneDefinition.theme);
    
    return InteractionFeedbackController(
      child: Semantics(
        label: 'Scene with ${sceneDefinition.actorAssets.length} actors',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            gradient: theme.backgroundGradient,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildLayer(sceneDefinition.backgroundAssets, 0.4, 'background'),
              _buildLayer(sceneDefinition.actorAssets, 1.0, 'actor'),
              _buildLayer(sceneDefinition.effectAssets, 0.8, 'effect'),
              SceneEffectController(
                world: world,
                sceneId: sceneDefinition.sceneId,
                behaviors: sceneDefinition.behaviors,
                effects: sceneDefinition.effects,
              ),
              RuntimeCanvasView(
                canvas: world.simulationCanvas,
                backgroundColor: Colors.transparent,
              ),
              SceneControlsOverlay(
                world: world,
                sceneId: sceneDefinition.sceneId,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayer(List<String> assets, double opacity, String layerType) {
    if (assets.isEmpty) return const SizedBox.shrink();
    if (sceneDefinition.sceneId.contains('pendulum') && layerType == 'actor') return const SizedBox.shrink();
    if (sceneDefinition.sceneId.contains('plant_growth') && layerType == 'actor') return const SizedBox.shrink();
    
    // Simplistic layout mapping: center them evenly
    return Opacity(
      opacity: opacity,
      child: Stack(
        fit: StackFit.expand,
        children: assets.map((assetPath) {
          Widget svgNode = SvgPicture.asset(
            assetPath,
            fit: BoxFit.contain,
          );

          svgNode = VisualResponseController(
            world: world,
            sceneId: sceneDefinition.sceneId,
            layerType: layerType,
            child: svgNode,
          );

          svgNode = IdleAnimationController(
            sceneId: sceneDefinition.sceneId,
            layerType: layerType,
            child: svgNode,
          );

          return Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: svgNode,
            ),
          );
        }).toList(),
      ),
    );
  }
}


