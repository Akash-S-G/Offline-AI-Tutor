import 'visual_motion_spec.dart';
import 'visual_parameter_response.dart';

class VisualizationFirstProfile {
  final String presetId;
  final String environmentId;
  final List<VisualMotionSpec> idleMotions;
  final List<VisualParameterResponse> parameterResponses;
  final List<String> particleSystems;
  final List<String> graphAnimations;
  final List<String> narratedEvents;
  final List<String> focusTargets;

  const VisualizationFirstProfile({
    required this.presetId,
    required this.environmentId,
    required this.idleMotions,
    this.parameterResponses = const [],
    this.particleSystems = const [],
    this.graphAnimations = const [],
    this.narratedEvents = const [],
    this.focusTargets = const [],
  });

  bool get hasImmediateMotion {
    return idleMotions.any((motion) => motion.satisfiesAliveRequirement);
  }

  bool get hasParameterDrivenAnimation {
    return parameterResponses.any((response) => response.isValid);
  }

  bool get isCertified {
    return presetId.isNotEmpty &&
        environmentId.isNotEmpty &&
        hasImmediateMotion &&
        hasParameterDrivenAnimation &&
        idleMotions.every((motion) => motion.satisfiesAliveRequirement);
  }

  Map<String, dynamic> toJson() {
    return {
      'presetId': presetId,
      'environmentId': environmentId,
      'idleMotions': idleMotions.map((motion) => motion.toJson()).toList(),
      'parameterResponses': parameterResponses
          .map((response) => response.toJson())
          .toList(),
      'particleSystems': particleSystems,
      'graphAnimations': graphAnimations,
      'narratedEvents': narratedEvents,
      'focusTargets': focusTargets,
      'isCertified': isCertified,
    };
  }
}
