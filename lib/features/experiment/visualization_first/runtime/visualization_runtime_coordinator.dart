import '../../runtime/runtime_event.dart';
import '../../runtime/runtime_event_bus.dart';
import '../../runtime/simulation/animations/runtime_animation_engine.dart';
import '../../runtime/simulation/canvas/runtime_simulation_canvas.dart';
import '../environments/visual_environment_library.dart';
import '../focus/visual_focus_policy.dart';
import '../particles/generic_particle_library.dart';
import 'runtime_visualization_state.dart';
import 'visualization_animation_injector.dart';
import 'visualization_parameter_controller.dart';
import 'visualization_particle_controller.dart';
import 'visualization_profile_resolver.dart';

class VisualizationRuntimeCoordinator {
  VisualizationRuntimeCoordinator({
    required RuntimeEventBus eventBus,
    required RuntimeSimulationCanvas canvas,
    required RuntimeAnimationEngine animationEngine,
    VisualizationProfileResolver resolver =
        const VisualizationProfileResolver(),
    VisualizationAnimationInjector animationInjector =
        const VisualizationAnimationInjector(),
    VisualizationParticleController? particleController,
  }) : _eventBus = eventBus,
       _canvas = canvas,
       _animationEngine = animationEngine,
       _resolver = resolver,
       _animationInjector = animationInjector,
       _particleController =
           particleController ?? VisualizationParticleController();

  final RuntimeEventBus _eventBus;
  final RuntimeSimulationCanvas _canvas;
  final RuntimeAnimationEngine _animationEngine;
  final VisualizationProfileResolver _resolver;
  final VisualizationAnimationInjector _animationInjector;
  final VisualizationParticleController _particleController;
  VisualizationParameterController? _parameterController;

  RuntimeVisualizationState? state;

  RuntimeVisualizationState initialize(Map<String, dynamic> metadata) {
    _parameterController?.dispose();
    final profile = _resolver.resolve(
      visualPreset: metadata['visualPreset']?.toString(),
      metadata: metadata,
    );
    final environment = VisualEnvironmentLibrary.byId(profile.environmentId);
    final particleProfiles = profile.particleSystems
        .map((id) {
          return GenericParticleLibrary.all.where(
            (profile) => profile.id == id,
          );
        })
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .take(3)
        .toList(growable: false);

    final particleAnimations = _particleController.attachParticles(
      canvas: _canvas,
      profiles: particleProfiles,
    );
    final idleAnimations = _animationInjector.animationsFor(profile, _canvas);
    _animationEngine.addAnimations([...idleAnimations, ...particleAnimations]);
    _parameterController = VisualizationParameterController(
      eventBus: _eventBus,
      canvas: _canvas,
      profile: profile,
    )..attach();

    final next = RuntimeVisualizationState(
      activeProfile: profile,
      activeEnvironment: environment,
      activeParticles: particleProfiles,
      activeNarration: profile.narratedEvents,
      activeFocusPolicy: const VisualFocusPolicy(),
      activeAnimations: idleAnimations.length + particleAnimations.length,
      particlesSpawned: _particleController.spawnedCount,
    );
    state = next;
    _emit('VisualizationProfileLoaded', {
      'profile': profile.presetId,
      'environment': environment.id,
      'particleSystems': particleProfiles.map((p) => p.id).toList(),
      'activeAnimations': next.activeAnimations,
      'particlesSpawned': next.particlesSpawned,
    });
    _emit('IdleAnimationsStarted', {
      'profile': profile.presetId,
      'count': idleAnimations.length,
    });
    if (particleProfiles.isNotEmpty) {
      _emit('ParticlesSpawned', {
        'count': _particleController.spawnedCount,
        'systems': particleProfiles.map((p) => p.id).toList(),
      });
    }
    return next;
  }

  void dispose() {
    _parameterController?.dispose();
  }

  void _emit(String message, Map<String, dynamic> metadata) {
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
}
