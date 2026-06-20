import 'behavior.dart';

/// Directional particle flow along a path (circuit current, river, wind).
/// Outputs 'flow_progress' — a 0.0–1.0 value representing particle position along path.
///
/// Params:
///   speed_var    : variable ID controlling flow speed (default: 'var_current')
///   is_active_var: variable ID for flow enabled state (default: 'var_switch_state')
class FlowBehavior implements Behavior {
  @override
  String get type => 'flow';

  @override
  void tick(double time, BehaviorContext context) {
    final isActive = context.get(
      context.params['is_active_var'] as String? ?? 'var_switch_state',
    );
    if (isActive < 0.5) {
      context.setOutput('flow_progress', 0.0);
      return;
    }

    final speed = context.get(
      context.params['speed_var'] as String? ?? 'var_current',
      defaultValue: 1.0,
    );

    // Progress cycles 0→1 repeatedly at a rate proportional to speed.
    final progress = (time * speed * 0.2) % 1.0;
    context.setOutput('flow_progress', progress);
    context.setOutput('flow_speed', speed);
  }
}
