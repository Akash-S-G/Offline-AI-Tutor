import 'behavior.dart';

/// Vertical scale increase representing biological or physical growth.
/// Outputs 'growth_scale' — 0.0 to 2.0+ scale applied from the bottom.
///
/// Params:
///   growth_var  : variable ID for growth level 0–100 (default: 'var_growth')
///   min_scale   : scale at growth == 0 (default: 0.05)
///   max_scale   : scale at growth == 100 (default: 1.5)
class GrowthBehavior implements Behavior {
  @override
  String get type => 'growth';

  @override
  void tick(double time, BehaviorContext context) {
    final growthPct = context.get(
      context.params['growth_var'] as String? ?? 'var_growth',
      defaultValue: 0.0,
    ).clamp(0.0, 100.0);

    final minScale = (context.params['min_scale'] as num?)?.toDouble() ?? 0.05;
    final maxScale = (context.params['max_scale'] as num?)?.toDouble() ?? 1.5;

    final scale = minScale + (growthPct / 100.0) * (maxScale - minScale);

    context.setOutput('growth_scale', scale);
    context.setOutput('growth_pct', growthPct);
  }
}
