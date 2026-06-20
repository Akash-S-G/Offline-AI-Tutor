/// A declared transition between two simulation states.
/// Condition is evaluated each frame by the [StateMachine].
class StateTransition {
  /// Source state ID. Use '*' to match any state.
  final String from;

  /// Target state ID.
  final String to;

  /// Variable-based condition: { variable, operator, value }
  final Map<String, dynamic> condition;

  const StateTransition({
    required this.from,
    required this.to,
    required this.condition,
  });

  factory StateTransition.fromJson(Map<String, dynamic> json) {
    return StateTransition(
      from: json['from'] as String? ?? '*',
      to: json['to'] as String,
      condition: Map<String, dynamic>.from(json['condition'] as Map? ?? {}),
    );
  }
}
