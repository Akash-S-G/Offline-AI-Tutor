/// Base interface for all simulation behaviors.
/// A behavior is a reusable, time-driven motion or physics logic applied to
/// a named target in the scene.
abstract class Behavior {
  /// Unique type identifier (e.g. 'oscillation', 'flow', 'pulse')
  String get type;

  /// Called every frame with the elapsed simulation time.
  /// Reads variables from [vars], writes updated display values back.
  void tick(double time, BehaviorContext context);
}

/// Context passed to each behavior tick, giving it access to simulation state.
class BehaviorContext {
  final Map<String, double> variables;
  final Map<String, dynamic> params;
  final void Function(String key, double value) setOutput;

  const BehaviorContext({
    required this.variables,
    required this.params,
    required this.setOutput,
  });

  double get(String varId, {double defaultValue = 0.0}) =>
      variables[varId] ?? defaultValue;
}
