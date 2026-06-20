import 'state_machine.dart';
import 'simulation_state.dart';

/// Resolves the active [SimulationState] from a [StateMachine].
/// Used by the rendering layer to query what state the scene is in
/// without coupling to the state machine internals.
class StateResolver {
  final StateMachine _machine;

  StateResolver(this._machine);

  SimulationState? get current => _machine.current;
  String? get currentId => _machine.currentId;

  bool isState(String id) => _machine.currentId == id;

  bool isAnyOf(List<String> ids) => ids.contains(_machine.currentId);

  /// Tick the machine with the latest variable snapshot.
  void tick(Map<String, double> variables) {
    _machine.evaluate(variables);
  }
}
