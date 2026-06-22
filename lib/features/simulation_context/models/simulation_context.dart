/// Snapshot of the currently running experiment's state.
///
/// Sent to the backend with every voice request so the tutor
/// knows what the student is looking at.
class SimulationContext {
  const SimulationContext({
    this.experimentId,
    this.experimentName,
    this.variables = const {},
    this.currentState = '',
  });

  /// Unique identifier of the running experiment.
  final String? experimentId;

  /// Human-readable name (e.g. "Water Cycle").
  final String? experimentName;

  /// Current variable values from the runtime engine.
  final Map<String, dynamic> variables;

  /// Current state label (e.g. "raining", "evaporating").
  final String currentState;

  /// Whether an experiment is actively running.
  bool get hasContext => experimentId != null;

  /// Serialize for inclusion in voice request payloads.
  Map<String, dynamic> toJson() => {
        'experiment': experimentName ?? experimentId ?? '',
        'variables': variables,
        'state': currentState,
      };

  SimulationContext copyWith({
    String? experimentId,
    String? experimentName,
    Map<String, dynamic>? variables,
    String? currentState,
    bool clearContext = false,
  }) {
    if (clearContext) return const SimulationContext();
    return SimulationContext(
      experimentId: experimentId ?? this.experimentId,
      experimentName: experimentName ?? this.experimentName,
      variables: variables ?? this.variables,
      currentState: currentState ?? this.currentState,
    );
  }

  @override
  String toString() =>
      'SimulationContext($experimentName, state=$currentState, vars=${variables.length})';
}
