import '../environments/visual_environment_profile.dart';
import '../focus/visual_focus_policy.dart';
import '../models/visualization_first_profile.dart';
import '../particles/particle_system_profile.dart';

class RuntimeVisualizationState {
  final VisualizationFirstProfile activeProfile;
  final VisualEnvironmentProfile activeEnvironment;
  final List<ParticleSystemProfile> activeParticles;
  final List<String> activeNarration;
  final VisualFocusPolicy activeFocusPolicy;
  final int activeAnimations;
  final int particlesSpawned;

  const RuntimeVisualizationState({
    required this.activeProfile,
    required this.activeEnvironment,
    required this.activeParticles,
    required this.activeNarration,
    required this.activeFocusPolicy,
    this.activeAnimations = 0,
    this.particlesSpawned = 0,
  });

  RuntimeVisualizationState copyWith({
    VisualizationFirstProfile? activeProfile,
    VisualEnvironmentProfile? activeEnvironment,
    List<ParticleSystemProfile>? activeParticles,
    List<String>? activeNarration,
    VisualFocusPolicy? activeFocusPolicy,
    int? activeAnimations,
    int? particlesSpawned,
  }) {
    return RuntimeVisualizationState(
      activeProfile: activeProfile ?? this.activeProfile,
      activeEnvironment: activeEnvironment ?? this.activeEnvironment,
      activeParticles: activeParticles ?? this.activeParticles,
      activeNarration: activeNarration ?? this.activeNarration,
      activeFocusPolicy: activeFocusPolicy ?? this.activeFocusPolicy,
      activeAnimations: activeAnimations ?? this.activeAnimations,
      particlesSpawned: particlesSpawned ?? this.particlesSpawned,
    );
  }
}
