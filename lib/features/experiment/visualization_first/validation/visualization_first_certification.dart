import '../environments/visual_environment_library.dart';
import '../graphs/animated_graph_profile_registry.dart';
import '../models/visualization_first_profile.dart';
import '../particles/generic_particle_library.dart';

class VisualizationFirstCertificationResult {
  final String presetId;
  final bool hasIdleMotion;
  final bool startsWithinThreeSeconds;
  final bool hasParameterResponse;
  final bool hasMobileSafeParticles;
  final bool hasAnimatedGraphs;
  final bool hasLightweightEnvironment;
  final List<String> failures;

  const VisualizationFirstCertificationResult({
    required this.presetId,
    required this.hasIdleMotion,
    required this.startsWithinThreeSeconds,
    required this.hasParameterResponse,
    required this.hasMobileSafeParticles,
    required this.hasAnimatedGraphs,
    required this.hasLightweightEnvironment,
    this.failures = const [],
  });

  bool get passed {
    return hasIdleMotion &&
        startsWithinThreeSeconds &&
        hasParameterResponse &&
        hasMobileSafeParticles &&
        hasAnimatedGraphs &&
        hasLightweightEnvironment &&
        failures.isEmpty;
  }
}

class VisualizationFirstCertifier {
  const VisualizationFirstCertifier();

  VisualizationFirstCertificationResult certify(
    VisualizationFirstProfile profile,
  ) {
    final failures = <String>[];
    final environment = VisualEnvironmentLibrary.byId(profile.environmentId);
    final knownParticles = GenericParticleLibrary.all.map((p) => p.id).toSet();
    final knownGraphs = AnimatedGraphProfileRegistry.all
        .map((graph) => graph.graphType)
        .toSet();

    final hasIdleMotion = profile.idleMotions.isNotEmpty;
    final startsWithinThreeSeconds = profile.idleMotions.every(
      (motion) => motion.satisfiesAliveRequirement,
    );
    final hasParameterResponse = profile.parameterResponses.any(
      (response) => response.isValid,
    );
    final hasMobileSafeParticles = profile.particleSystems.every((id) {
      final match = GenericParticleLibrary.all.where((p) => p.id == id);
      return match.isEmpty || match.first.isMobileSafe;
    });
    final hasAnimatedGraphs =
        profile.graphAnimations.isEmpty ||
        profile.graphAnimations.every(knownGraphs.contains);
    final hasLightweightEnvironment = environment.isLightweight;

    if (!hasIdleMotion) failures.add('No idle motion configured.');
    if (!startsWithinThreeSeconds) {
      failures.add('One or more idle motions do not start within 3 seconds.');
    }
    if (!hasParameterResponse) {
      failures.add('No parameter-driven animation response configured.');
    }
    if (!hasMobileSafeParticles) {
      failures.add('Particle system exceeds mobile-safe limits.');
    }
    if (!hasAnimatedGraphs) failures.add('Unknown graph animation profile.');
    if (!hasLightweightEnvironment) {
      failures.add('Environment is not lightweight/mobile-safe.');
    }
    for (final id in profile.particleSystems) {
      if (!knownParticles.contains(id)) {
        failures.add('Unknown particle system: $id');
      }
    }

    return VisualizationFirstCertificationResult(
      presetId: profile.presetId,
      hasIdleMotion: hasIdleMotion,
      startsWithinThreeSeconds: startsWithinThreeSeconds,
      hasParameterResponse: hasParameterResponse,
      hasMobileSafeParticles: hasMobileSafeParticles,
      hasAnimatedGraphs: hasAnimatedGraphs,
      hasLightweightEnvironment: hasLightweightEnvironment,
      failures: failures,
    );
  }

  List<VisualizationFirstCertificationResult> certifyAll(
    Iterable<VisualizationFirstProfile> profiles,
  ) {
    return profiles.map(certify).toList(growable: false);
  }
}
