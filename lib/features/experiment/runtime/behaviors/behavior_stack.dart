import 'behavior.dart';
import 'behavior_registry.dart';
import 'behavior_executor.dart';

/// Runs multiple behaviors in sequence and accumulates all their outputs
/// into a single flat map. Later behaviors can read outputs from earlier ones.
///
/// This replaces the inline single-behavior tick in the painter and is the
/// generic composition mechanism: oscillation + glow + trail simultaneously.
class BehaviorStack {
  final List<BehaviorDescriptor> _descriptors;

  BehaviorStack(List<dynamic> rawBehaviors)
      : _descriptors = rawBehaviors
            .map((b) => BehaviorDescriptor.fromJson(b as Map<String, dynamic>))
            .toList();

  /// Tick all behaviors. Returns a merged output map.
  Map<String, double> tick({
    required double time,
    required Map<String, double> variables,
  }) {
    final outputs = <String, double>{};

    for (final descriptor in _descriptors) {
      final behavior = BehaviorRegistry.resolve(descriptor.type);
      if (behavior == null) continue;

      // Merge current outputs into variables so each behavior can read
      // what the previous ones produced.
      final merged = {...variables, ...outputs};

      final context = BehaviorContext(
        variables: merged,
        params: descriptor.params,
        setOutput: (key, value) => outputs[key] = value,
      );

      behavior.tick(time, context);
    }

    return outputs;
  }
}
