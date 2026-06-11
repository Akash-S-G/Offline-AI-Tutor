import 'dart:math' as math;

import '../../runtime_event.dart';
import '../../runtime_event_bus.dart';
import '../canvas/runtime_simulation_canvas.dart';
import 'runtime_animation.dart';

class RuntimeAnimationEngine {
  RuntimeAnimationEngine({
    required RuntimeSimulationCanvas canvas,
    required RuntimeEventBus eventBus,
  }) : _canvas = canvas,
       _eventBus = eventBus;

  final RuntimeSimulationCanvas _canvas;
  final RuntimeEventBus _eventBus;
  final List<RuntimeAnimation> _animations = [];
  final Map<String, double> _elapsedByAnimation = {};

  List<RuntimeAnimation> get animations => List.unmodifiable(_animations);
  int get animationCount => _animations.length;
  int get runningAnimationCount =>
      _animations.where((animation) => animation.enabled).length;

  void initialize(List<Map<String, dynamic>> animationsJson) {
    _animations
      ..clear()
      ..addAll(animationsJson.map(RuntimeAnimation.fromJson));
    _elapsedByAnimation.clear();
    for (final animation in _animations.where(
      (animation) => animation.enabled,
    )) {
      _elapsedByAnimation[animation.id] = 0;
      _emit('AnimationStarted', metadata: animation.toJson());
    }
  }

  void addAnimations(List<RuntimeAnimation> animations) {
    for (final animation in animations) {
      if (_animations.any((existing) => existing.id == animation.id)) continue;
      _animations.add(animation);
      if (animation.enabled) {
        _elapsedByAnimation[animation.id] = 0;
        _emit('AnimationStarted', metadata: animation.toJson());
      }
    }
  }

  void tick(double dt, double runtimeSeconds) {
    for (final animation in _animations) {
      if (!animation.enabled || !animation.supported) continue;
      final elapsed = (_elapsedByAnimation[animation.id] ?? 0) + dt;
      _elapsedByAnimation[animation.id] = animation.repeat
          ? elapsed % animation.duration.clamp(0.001, double.infinity)
          : elapsed.clamp(0, animation.duration);
      _apply(animation, runtimeSeconds, _elapsedByAnimation[animation.id]!, dt);
    }
  }

  void dispose() {
    _animations.clear();
    _elapsedByAnimation.clear();
  }

  void _apply(
    RuntimeAnimation animation,
    double runtimeSeconds,
    double elapsed,
    double dt,
  ) {
    final actor = _canvas.actor(animation.actorId);
    if (actor == null) return;
    final progress =
        (elapsed / animation.duration.clamp(0.001, double.infinity))
            .clamp(0, 1)
            .toDouble();
    final state = animation.state;
    switch (animation.type) {
      case 'move':
        final fromX = _double(state['fromX'], fallback: actor.positionX);
        final fromY = _double(state['fromY'], fallback: actor.positionY);
        final toX = _double(state['toX'], fallback: actor.positionX);
        final toY = _double(state['toY'], fallback: actor.positionY);
        _canvas.updateActor(
          actor.copyWith(
            positionX: _lerp(fromX, toX, progress),
            positionY: _lerp(fromY, toY, progress),
          ),
        );
      case 'rotate':
        final speed = _double(state['speed'], fallback: math.pi);
        _canvas.updateActorProperty(
          actor.id,
          'rotation',
          actor.rotation + speed * dt,
        );
      case 'scale':
        final from = _double(state['from'], fallback: actor.scale);
        final to = _double(state['to'], fallback: actor.scale);
        _canvas.updateActorProperty(
          actor.id,
          'scale',
          _lerp(from, to, progress),
        );
      case 'fade':
        final from = _double(state['from'], fallback: actor.opacity);
        final to = _double(state['to'], fallback: actor.opacity);
        _canvas.updateActorProperty(
          actor.id,
          'opacity',
          _lerp(from, to, progress),
        );
      case 'pulse':
        final base = _double(state['base'], fallback: 1);
        final amplitude = _double(state['amplitude'], fallback: 0.12);
        final frequency = _double(state['frequency'], fallback: 1);
        _canvas.updateActorProperty(
          actor.id,
          'scale',
          base + amplitude * math.sin(runtimeSeconds * math.pi * 2 * frequency),
        );
      case 'oscillate':
        final property = state['property']?.toString() ?? 'rotation';
        final base = _double(state['base']);
        final amplitude = _double(state['amplitude'], fallback: math.pi / 8);
        final frequency = _double(state['frequency'], fallback: 1);
        _canvas.updateActorProperty(
          actor.id,
          property,
          base + amplitude * math.sin(runtimeSeconds * math.pi * 2 * frequency),
        );
      case 'orbit':
        final centerX = _double(state['centerX']);
        final centerY = _double(state['centerY']);
        final radius = _double(state['radius'], fallback: 40);
        final speed = _double(state['speed'], fallback: 1);
        final angle = runtimeSeconds * speed;
        _canvas.updateActor(
          actor.copyWith(
            positionX: centerX + radius * math.cos(angle),
            positionY: centerY + radius * math.sin(angle),
          ),
        );
    }
    _emit(
      'AnimationUpdated',
      metadata: {
        'animationId': animation.id,
        'actorId': animation.actorId,
        'type': animation.type,
      },
    );
  }

  void _emit(String message, {Map<String, dynamic>? metadata}) {
    _eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: metadata,
      ),
    );
  }

  double _lerp(double from, double to, double progress) {
    return from + (to - from) * progress;
  }

  static double _double(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
