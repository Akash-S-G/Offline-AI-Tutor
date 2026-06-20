import 'simulation_state.dart';
import 'state_transition.dart';

/// Manages which [SimulationState] is currently active and evaluates
/// transition conditions against the live variable map.
class StateMachine {
  final List<SimulationState> _states;
  final List<StateTransition> _transitions;

  SimulationState? _current;

  StateMachine({
    required List<SimulationState> states,
    required List<StateTransition> transitions,
    String? initialState,
  })  : _states = states,
        _transitions = transitions {
    if (initialState != null) {
      _current = _resolve(initialState);
    } else if (states.isNotEmpty) {
      _current = states.first;
    }
  }

  factory StateMachine.fromJson(List<dynamic> statesJson, List<dynamic> transitionsJson) {
    final states = statesJson
        .map((s) => s is String
            ? SimulationState.fromString(s)
            : SimulationState.fromJson(s as Map<String, dynamic>))
        .toList();

    final transitions = transitionsJson
        .map((t) => StateTransition.fromJson(t as Map<String, dynamic>))
        .toList();

    return StateMachine(states: states, transitions: transitions);
  }

  SimulationState? get current => _current;
  String? get currentId => _current?.id;

  /// Evaluate all transitions against current variable values.
  /// The first matching transition wins.
  void evaluate(Map<String, double> variables) {
    for (final t in _transitions) {
      if (t.from == _current?.id || t.from == '*') {
        if (_evaluate(t.condition, variables)) {
          final next = _resolve(t.to);
          if (next != null && next != _current) {
            _current = next;
            return; // only one transition per tick
          }
        }
      }
    }
  }

  SimulationState? _resolve(String id) =>
      _states.firstWhere((s) => s.id == id, orElse: () => _states.first);

  bool _evaluate(Map<String, dynamic> condition, Map<String, double> vars) {
    final varId = condition['variable'] as String?;
    final op = condition['operator'] as String? ?? '>=';
    final threshold = (condition['value'] as num?)?.toDouble() ?? 0.0;
    if (varId == null) return false;
    final val = vars[varId] ?? 0.0;
    switch (op) {
      case '>':  return val > threshold;
      case '>=': return val >= threshold;
      case '<':  return val < threshold;
      case '<=': return val <= threshold;
      case '==': return val == threshold;
      case '!=': return val != threshold;
      default:   return false;
    }
  }
}
