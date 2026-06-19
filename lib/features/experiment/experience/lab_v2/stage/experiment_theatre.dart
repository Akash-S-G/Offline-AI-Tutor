import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../runtime/runtime_world.dart';
import '../../../runtime/simulation/renderers/runtime_canvas_renderer.dart';
import '../../scenes/scene_definition_v3.dart';
import '../../scenes/scene_themes.dart';

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
    
    return Semantics(
      label: 'Scene with ${sceneDefinition.actorAssets.length} actors',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          gradient: theme.backgroundGradient,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildLayer(sceneDefinition.backgroundAssets, 0.4),
            _buildLayer(sceneDefinition.actorAssets, 1.0),
            _buildLayer(sceneDefinition.effectAssets, 0.8),
            RuntimeCanvasView(
              canvas: world.simulationCanvas,
              backgroundColor: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayer(List<String> assets, double opacity) {
    if (assets.isEmpty) return const SizedBox.shrink();
    
    // Simplistic layout mapping: center them evenly
    return Opacity(
      opacity: opacity,
      child: Stack(
        fit: StackFit.expand,
        children: assets.map((assetPath) {
          return Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: SvgPicture.asset(
                assetPath,
                fit: BoxFit.contain,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


