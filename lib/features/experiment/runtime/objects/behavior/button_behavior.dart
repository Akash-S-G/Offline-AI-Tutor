import '../../models/runtime_object_state.dart';
import 'runtime_object_behavior.dart';

class ButtonBehavior extends PlaceholderRuntimeObjectBehavior {
  @override
  ValidationResult validateState(RuntimeObjectState state) {
    final pressed = state.state['pressed'];
    final enabled = state.state['enabled'];
    final pressCount = state.state['pressCount'];
    final errors = <String>[];
    if (pressed is! bool) errors.add('pressed must be a boolean');
    if (enabled is! bool) errors.add('enabled must be a boolean');
    if (pressCount is! num) errors.add('pressCount must be numeric');
    return errors.isEmpty
        ? const ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }
}
