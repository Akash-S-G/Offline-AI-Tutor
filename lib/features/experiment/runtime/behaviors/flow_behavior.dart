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
    final speed = context.get(
      context.params['speed_var'] as String? ?? 'var_current',
      defaultValue: 1.0,
    );

    final activeVarName = context.params['is_active_var'] as String?;
    
    if (activeVarName != null) {
      final isActive = context.get(activeVarName);
      if (isActive < 0.5) {
        context.setOutput('flow_progress', 0.0);
        return;
      }
    } else if (speed <= 0) {
      // If no explicit switch is mapped, just stop flow if speed is 0
      context.setOutput('flow_progress', 0.0);
      return;
    }

    // Progress cycles 0→1 repeatedly at a rate proportional to speed.
    final progress = (time * speed * 0.2) % 1.0;
    context.setOutput('flow_progress', progress);
    context.setOutput('flow_speed', speed);
  }
}
