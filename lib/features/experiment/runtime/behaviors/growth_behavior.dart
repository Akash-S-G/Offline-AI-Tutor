import 'behavior.dart';

/// Scale increase representing biological or physical growth.
/// Configurable generic outputs based on a growth variable.
///
/// Params:
///   growth_var : variable ID for growth level 0-100 (default: 'growth')
///   outputs    : map of output keys to min/max values
///     Example: { "height": { "min": 0.0, "max": 2.0 } }
class GrowthBehavior implements Behavior {
  @override
  String get type => 'growth';

  @override
  void tick(double time, BehaviorContext context) {
    final growthPct = context.get(
      context.params['growth_var'] as String? ?? 'growth',
      defaultValue: 0.0,
    ).clamp(0.0, 100.0);

    final outputs = context.params['outputs'] as Map<String, dynamic>? ?? {};

    if (outputs.isEmpty) {
      // Fallback for legacy
      final minScale = (context.params['min_scale'] as num?)?.toDouble() ?? 0.05;
      final maxScale = (context.params['max_scale'] as num?)?.toDouble() ?? 1.5;
      final scale = minScale + (growthPct / 100.0) * (maxScale - minScale);
      context.setOutput('growth_scale', scale);
    } else {
      outputs.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final minVal = (value['min'] as num?)?.toDouble() ?? 0.0;
          final maxVal = (value['max'] as num?)?.toDouble() ?? 1.0;
          final outVal = minVal + (growthPct / 100.0) * (maxVal - minVal);
          context.setOutput(key, outVal);
        }
      });
    }

    context.setOutput('growth_pct', growthPct);
  }
}
