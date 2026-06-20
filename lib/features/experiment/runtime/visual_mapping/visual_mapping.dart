/// A single visual mapping rule from the blueprint JSON.
/// Maps a variable value to a named effect type.
///
/// Example JSON:
/// ```json
/// { "variable": "temperature", "effect": "glow", "min": 0, "max": 40 }
/// ```
class VisualMapping {
  /// Variable ID to watch.
  final String variable;

  /// Effect type to activate (matches effects registered in SceneEffectController).
  final String effect;

  /// Optional variable range for normalization.
  final double min;
  final double max;

  /// Optional: threshold above which this mapping activates.
  final double? threshold;

  const VisualMapping({
    required this.variable,
    required this.effect,
    this.min = 0.0,
    this.max = 100.0,
    this.threshold,
  });

  factory VisualMapping.fromJson(Map<String, dynamic> json) {
    return VisualMapping(
      variable: json['variable'] as String,
      effect: json['effect'] as String,
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 100.0,
      threshold: (json['threshold'] as num?)?.toDouble(),
    );
  }

  /// Returns normalized intensity (0.0–1.0) for the given raw variable value.
  double intensity(double value) {
    if (threshold != null && value < threshold!) return 0.0;
    if (max == min) return 0.0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }
}
