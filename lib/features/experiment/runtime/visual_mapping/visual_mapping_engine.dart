import 'visual_mapping.dart';

/// Result from a resolved visual mapping: the effect type and its intensity.
class MappingResult {
  final String effect;
  final double intensity;

  const MappingResult({required this.effect, required this.intensity});
}

/// Evaluates all [VisualMapping] rules for the current variable snapshot
/// and returns a map of active effect types → intensity values.
///
/// This is the single place where variable values become visual decisions.
/// No experiment-specific if/else — just mapping resolution.
class VisualMappingEngine {
  final List<VisualMapping> _mappings;

  VisualMappingEngine(List<Map<String, dynamic>> rawMappings)
      : _mappings = rawMappings.map(VisualMapping.fromJson).toList();

  /// Evaluate all mappings against the current variable values.
  /// Returns a map of { effectType → intensity }.
  Map<String, double> evaluate(Map<String, double> variables) {
    final results = <String, double>{};
    for (final mapping in _mappings) {
      final value = variables[mapping.variable] ?? 0.0;
      final intensity = mapping.intensity(value);
      if (intensity > 0.0) {
        // If multiple mappings target the same effect, take the max intensity
        results[mapping.effect] = intensity > (results[mapping.effect] ?? 0.0)
            ? intensity
            : results[mapping.effect]!;
      }
    }
    return results;
  }

  /// Convenience: check if an effect is active above a minimum intensity.
  bool isActive(String effect, Map<String, double> variables, {double minIntensity = 0.01}) {
    final results = evaluate(variables);
    return (results[effect] ?? 0.0) >= minIntensity;
  }
}
