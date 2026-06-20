import 'dart:math' as math;
import 'behavior.dart';

/// Circular orbital motion around a pivot point.
/// Outputs 'orbit_x' and 'orbit_y' as normalized offsets (-1.0 to 1.0).
///
/// Params:
///   speed_var    : variable ID controlling angular speed (default: 'var_speed')
///   radius_var   : variable ID controlling orbit radius  (default: 'var_radius')
///   speed_scale  : multiplier for the speed variable     (default: 0.5)
class OrbitBehavior implements Behavior {
  @override
  String get type => 'orbit';

  @override
  void tick(double time, BehaviorContext context) {
    final speed = context.get(
      context.params['speed_var'] as String? ?? 'var_speed',
      defaultValue: 1.0,
    );

    final speedScale = (context.params['speed_scale'] as num?)?.toDouble() ?? 0.5;
    final angle = time * speed * speedScale;

    context.setOutput('orbit_x', math.cos(angle));
    context.setOutput('orbit_y', math.sin(angle));
    context.setOutput('orbit_angle', angle);
  }
}
