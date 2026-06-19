import 'dart:math' as math;

import '../../runtime/simulation/animations/runtime_animation.dart';
import '../../runtime/simulation/actors/particle_actor.dart';
import '../../runtime/simulation/canvas/runtime_simulation_canvas.dart';
import '../particles/particle_system_profile.dart';

class VisualizationParticleController {
  VisualizationParticleController({math.Random? random})
    : _random = random ?? math.Random(27);

  final math.Random _random;
  int _spawned = 0;

  int get spawnedCount => _spawned;

  List<RuntimeAnimation> attachParticles({
    required RuntimeSimulationCanvas canvas,
    required List<ParticleSystemProfile> profiles,
  }) {
    final animations = <RuntimeAnimation>[];
    var remaining = 50;
    for (final profile in profiles) {
      if (remaining <= 0) break;
      final count = math.min(remaining, math.max(6, profile.maxParticles ~/ 8));
      remaining -= count;
      for (var i = 0; i < count; i++) {
        final actorId = 'visual_particle_${profile.id}_$i';
        canvas.addActor(
          ParticleActor(
            id: actorId,
            positionX: 40 + _random.nextDouble() * 560,
            positionY: 50 + _random.nextDouble() * 300,
            opacity: 0.25 + _random.nextDouble() * 0.35,
            scale: 0.8 + _random.nextDouble() * 0.6,
            state: {
              'radius': _radiusFor(profile.particleType),
              'color': _colorFor(profile.particleType),
              'particleType': profile.particleType,
            },
          ),
          notify: false,
        );
        animations.add(_animationFor(profile, actorId, i));
        _spawned++;
      }
    }
    return animations;
  }

  RuntimeAnimation _animationFor(
    ParticleSystemProfile profile,
    String actorId,
    int index,
  ) {
    switch (profile.particleType) {
      case 'heat':
        return RuntimeAnimation(
          id: '${actorId}_rise',
          actorId: actorId,
          type: 'move',
          duration: 2.4 + (index % 4) * 0.25,
          state: const {'fromY': 320, 'toY': 40},
        );
      case 'water':
        return RuntimeAnimation(
          id: '${actorId}_fall',
          actorId: actorId,
          type: 'move',
          duration: 1.8 + (index % 5) * 0.2,
          state: const {'fromY': 40, 'toY': 340},
        );
      case 'spark':
        return RuntimeAnimation(
          id: '${actorId}_spark',
          actorId: actorId,
          type: 'fade',
          duration: 0.9,
          state: const {'from': 0.8, 'to': 0.05},
        );
      case 'trail':
        return RuntimeAnimation(
          id: '${actorId}_trail',
          actorId: actorId,
          type: 'fade',
          duration: 1.2,
          state: const {'from': 0.55, 'to': 0.08},
        );
      default:
        return RuntimeAnimation(
          id: '${actorId}_flow',
          actorId: actorId,
          type: 'move',
          duration: 3 + (index % 5) * 0.18,
          state: const {'fromX': -20, 'toX': 700},
        );
    }
  }

  double _radiusFor(String particleType) {
    switch (particleType) {
      case 'spark':
        return 3;
      case 'trail':
        return 4;
      default:
        return 5;
    }
  }

  String _colorFor(String particleType) {
    switch (particleType) {
      case 'heat':
        return '#f97316';
      case 'water':
        return '#38bdf8';
      case 'spark':
        return '#facc15';
      case 'trail':
        return '#93c5fd';
      default:
        return '#14b8a6';
    }
  }
}
