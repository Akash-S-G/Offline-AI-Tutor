import 'dart:math' as math;
import 'behavior.dart';
import '../formula/formula_evaluator.dart';

/// Sinusoidal back-and-forth oscillation.
/// Outputs: behavior_angle (radians), behavior_omega (rad/s)
///
/// Params (all optional, with sensible defaults):
///   frequency    : JSON formula string for angular frequency ω.
///                  Default formula: sqrt(9.81 / var_length)
///                  Can be overridden in blueprint JSON:
///                    "params": { "frequency": "sqrt(9.81 / var_length)" }
///   length_var   : variable ID for pendulum length (default: 'var_length')
///   angle_var    : variable ID for initial angle   (default: 'var_angle')
///   is_active_var: variable ID for swinging state  (default: 'var_is_swinging')
class OscillationBehavior implements Behavior {
  @override
  String get type => 'oscillation';

  @override
  void tick(double time, BehaviorContext context) {
    final isActiveVar = context.params['is_active_var'] as String? ?? 'var_is_swinging';
    final isActive = context.get(isActiveVar);
    if (isActive < 0.5) return; // not activated

    final lengthVar = context.params['length_var'] as String? ?? 'var_length';
    final angleVar  = context.params['angle_var']  as String? ?? 'var_angle';

    final length = context.get(lengthVar, defaultValue: 1.0).clamp(0.1, 10.0);
    final initialAngle = context.get(angleVar, defaultValue: 30.0);

    // ── Angular frequency ─────────────────────────────────────────────────────
    // Read from blueprint JSON formula if provided, otherwise fall back.
    final double omega;
    final formulaStr = context.params['frequency'] as String?;
    if (formulaStr != null && formulaStr.isNotEmpty) {
      omega = FormulaEvaluator.evaluate(formulaStr, {
        ...context.variables,
        // Ensure length is available by the standard variable name too
        'var_length': length,
        'length': length,
        'g': 9.81,
      });
    } else {
      omega = math.sqrt(9.81 / length);
    }

    // Convert degrees → radians (values ≥ 1.0 are assumed to be degrees)
    final angleRad = initialAngle >= 1.0
        ? initialAngle * math.pi / 180.0
        : initialAngle;

    // θ(t) = θ₀ · cos(ω · t)
    final currentAngle = angleRad * math.cos(omega * time);
    // dθ/dt = -θ₀ · ω · sin(ω · t)
    final angularVelocity = -angleRad * omega * math.sin(omega * time);

    context.setOutput('behavior_angle', currentAngle);
    context.setOutput('behavior_omega', omega);
    context.setOutput('behavior_angular_velocity', angularVelocity);
    // Normalized velocity magnitude 0..1 (max at bottom of swing)
    context.setOutput('behavior_velocity_norm',
        angularVelocity.abs() / (angleRad * omega).clamp(0.001, 100));
  }
}
