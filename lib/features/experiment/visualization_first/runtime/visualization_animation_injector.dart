import '../../runtime/simulation/animations/runtime_animation.dart';
import '../../runtime/simulation/canvas/runtime_simulation_canvas.dart';
import '../models/visual_motion_spec.dart';
import '../models/visualization_first_profile.dart';

class VisualizationAnimationInjector {
  const VisualizationAnimationInjector();

  List<RuntimeAnimation> animationsFor(
    VisualizationFirstProfile profile,
    RuntimeSimulationCanvas canvas,
  ) {
    final animations = <RuntimeAnimation>[];
    final fallbackActorId = _fallbackActorId(canvas);
    for (final motion in profile.idleMotions) {
      final actorId = motion.targetId == '*'
          ? fallbackActorId
          : motion.targetId;
      if (actorId == null || canvas.actor(actorId) == null) continue;
      animations.add(_toRuntimeAnimation(motion, actorId));
    }
    if (animations.isEmpty && fallbackActorId != null) {
      animations.add(
        RuntimeAnimation(
          id: 'visualization_generic_idle_$fallbackActorId',
          actorId: fallbackActorId,
          type: 'pulse',
          duration: 2,
          state: const {'base': 1, 'amplitude': 0.04, 'frequency': 0.5},
        ),
      );
    }
    return animations.take(30).toList(growable: false);
  }

  RuntimeAnimation _toRuntimeAnimation(
    VisualMotionSpec motion,
    String actorId,
  ) {
    final type = _runtimeTypeFor(motion.motionType);
    final state = <String, dynamic>{...motion.parameters};
    if (motion.motionType == 'flow') {
      state.addAll({'fromX': -40, 'toX': 680, 'fromY': 120, 'toY': 120});
    } else if (motion.motionType == 'trail') {
      state.addAll({'from': 0.15, 'to': 0.8});
    } else if (motion.motionType == 'grow') {
      state.addAll({'from': 0.96, 'to': 1.06});
    }
    return RuntimeAnimation(
      id: 'visualization_${motion.id}',
      actorId: actorId,
      type: type,
      duration: motion.durationSeconds,
      repeat: motion.repeats,
      state: state,
    );
  }

  String _runtimeTypeFor(String motionType) {
    switch (motionType) {
      case 'grow':
        return 'scale';
      case 'flow':
        return 'move';
      case 'trail':
        return 'fade';
      default:
        return motionType;
    }
  }

  String? _fallbackActorId(RuntimeSimulationCanvas canvas) {
    for (final actor in canvas.actors) {
      if (actor.visible && actor.type != 'text') return actor.id;
    }
    return canvas.actors.isEmpty ? null : canvas.actors.first.id;
  }
}
