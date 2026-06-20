import 'dart:math' as math;
import 'behavior.dart';

/// Periodic scale expand/contract pulse (heartbeat, pressure wave).
/// Outputs 'pulse_scale' — a scale multiplier for the target widget.
///
/// Params:
///   rate_var    : variable ID controlling BPM (default: 'var_heart_rate')
///   base_scale  : minimum scale (default: 1.0)
///   pulse_scale : maximum scale at peak (default: 1.3)
class PulseBehavior implements Behavior {
  @override
  String get type => 'pulse';

  @override
  void tick(double time, BehaviorContext context) {
    final bpm = context.get(
      context.params['rate_var'] as String? ?? 'var_heart_rate',
      defaultValue: 60.0,
    ).clamp(20.0, 220.0);

    final baseScale = (context.params['base_scale'] as num?)?.toDouble() ?? 1.0;
    final maxScale = (context.params['pulse_scale'] as num?)?.toDouble() ?? 1.3;

    // Frequency in Hz from BPM
    final hz = bpm / 60.0;
    // Sharp sawtooth-like pulse: sin² gives a quick peak and slow decay
    final raw = math.sin(time * hz * math.pi);
    final pulse = raw < 0 ? 0.0 : raw * raw;

    final scale = baseScale + (maxScale - baseScale) * pulse;
    context.setOutput('pulse_scale', scale);
    context.setOutput('pulse_intensity', pulse);
  }
}
