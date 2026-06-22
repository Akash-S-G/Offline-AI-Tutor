import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/simulation_context.dart';

// ─── Notifier ───────────────────────────────────────────────────────

class SimulationContextNotifier extends StateNotifier<SimulationContext> {
  SimulationContextNotifier() : super(const SimulationContext());

  /// Update the context when the experiment engine changes state.
  void update({
    String? experimentId,
    String? experimentName,
    Map<String, dynamic>? variables,
    String? currentState,
  }) {
    state = state.copyWith(
      experimentId: experimentId,
      experimentName: experimentName,
      variables: variables,
      currentState: currentState,
    );
  }

  /// Clear context when no experiment is running.
  void clear() {
    state = const SimulationContext();
  }
}

// ─── Provider ───────────────────────────────────────────────────────

final simulationContextProvider =
    StateNotifierProvider<SimulationContextNotifier, SimulationContext>((ref) {
  return SimulationContextNotifier();
});
