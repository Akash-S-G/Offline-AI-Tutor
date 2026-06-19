import '../models/visual_motion_spec.dart';
import '../models/visual_parameter_response.dart';
import '../models/visualization_first_profile.dart';
import '../registry/animation_first_preset_registry.dart';

class VisualizationProfileResolver {
  const VisualizationProfileResolver();

  VisualizationFirstProfile resolve({
    String? visualPreset,
    required Map<String, dynamic> metadata,
  }) {
    final candidates = <String>[
      ?visualPreset,
      metadata['visualPreset']?.toString() ?? '',
      metadata['sceneId']?.toString() ?? '',
      metadata['name']?.toString() ?? '',
      metadata['title']?.toString() ?? '',
    ].where((value) => value.trim().isNotEmpty).toList();

    for (final candidate in candidates) {
      final profile = _profileFor(candidate);
      if (profile != null) return profile;
    }
    return generic;
  }

  VisualizationFirstProfile? _profileFor(String raw) {
    final normalized = _normalize(raw);
    for (final profile in AnimationFirstPresetRegistry.all) {
      if (_normalize(profile.presetId) == normalized) return profile;
    }
    final aliases = {
      'freefall': 'freeFall',
      'freefall1': 'freeFall',
      'freefallexperiment': 'freeFall',
      'heartrate': 'heartRate',
      'heartrate1': 'heartRate',
      'heartratemonitor': 'heartRate',
      'pendulum': 'pendulum',
      'pendulum1': 'pendulum',
      'pendulummotion': 'pendulum',
      'plantgrowth': 'plantGrowth',
      'plantgrowth1': 'plantGrowth',
      'watercycle': 'waterCycle',
      'watercycle1': 'waterCycle',
    };
    final alias = aliases[normalized];
    return alias == null
        ? null
        : AnimationFirstPresetRegistry.byPresetId(alias);
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static const generic = VisualizationFirstProfile(
    presetId: 'generic',
    environmentId: 'laboratory',
    idleMotions: [
      VisualMotionSpec(
        id: 'generic_idle_pulse',
        targetId: '*',
        motionType: 'pulse',
        durationSeconds: 2,
        parameters: {'base': 1, 'amplitude': 0.04, 'frequency': 0.5},
      ),
    ],
    parameterResponses: [
      VisualParameterResponse(
        variableSemanticId: '*',
        targetId: '*',
        affectedProperty: 'pulse',
        responseDescription: 'A changed reading creates a visible pulse.',
      ),
    ],
    particleSystems: ['flow_particles'],
    graphAnimations: ['lineGraph'],
    narratedEvents: ['Experiment changed'],
    focusTargets: ['*'],
  );
}
