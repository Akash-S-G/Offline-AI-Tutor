class VisualMotionSpec {
  final String id;
  final String targetId;
  final String motionType;
  final double startsWithinSeconds;
  final double durationSeconds;
  final bool repeats;
  final Map<String, dynamic> parameters;

  const VisualMotionSpec({
    required this.id,
    required this.targetId,
    required this.motionType,
    this.startsWithinSeconds = 0,
    this.durationSeconds = 1,
    this.repeats = true,
    this.parameters = const {},
  });

  bool get satisfiesAliveRequirement {
    return targetId.isNotEmpty &&
        supportedMotionTypes.contains(motionType) &&
        startsWithinSeconds <= 3 &&
        durationSeconds > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetId': targetId,
      'motionType': motionType,
      'startsWithinSeconds': startsWithinSeconds,
      'durationSeconds': durationSeconds,
      'repeats': repeats,
      'parameters': parameters,
    };
  }

  static const supportedMotionTypes = {
    'move',
    'rotate',
    'pulse',
    'orbit',
    'oscillate',
    'fade',
    'flow',
    'trail',
    'grow',
  };
}
