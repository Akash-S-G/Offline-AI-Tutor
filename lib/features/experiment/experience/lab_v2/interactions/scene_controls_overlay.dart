import 'package:flutter/material.dart';
import '../../../runtime/runtime_world.dart';
import 'circuit_scene_controls.dart';
import 'pendulum_scene_controls.dart';
import 'water_cycle_scene_controls.dart';
import 'plant_growth_scene_controls.dart';
import 'heart_rate_scene_controls.dart';

class SceneControlsOverlay extends StatelessWidget {
  final RuntimeWorld world;
  final String sceneId;

  const SceneControlsOverlay({
    super.key,
    required this.world,
    required this.sceneId,
  });

  @override
  Widget build(BuildContext context) {
    if (sceneId.contains('pendulum')) {
      return PendulumSceneControls(world: world);
    } else if (sceneId.contains('circuit')) {
      return CircuitSceneControls(world: world);
    } else if (sceneId.contains('water_cycle')) {
      return WaterCycleSceneControls(world: world);
    } else if (sceneId.contains('plant_growth')) {
      return PlantGrowthSceneControls(world: world);
    } else if (sceneId.contains('heart_rate')) {
      return HeartRateSceneControls(world: world);
    }
    
    return const SizedBox.shrink(); // No custom controls defined for this scene
  }
}
