import '../../models/runtime_object_state.dart';
import 'runtime_object_behavior.dart';

class SliderBehavior extends PlaceholderRuntimeObjectBehavior {
  @override
  ValidationResult validateState(RuntimeObjectState state) {
    final errors = <String>[];
    final min = state.state['min'];
    final max = state.state['max'];
    final step = state.state['step'];
    final value = state.state['value'];
    final enabled = state.state['enabled'];
    if (min is num && max is num && min >= max) {
      errors.add('min must be less than max');
    }
    if (step is num && step <= 0) {
      errors.add('step must be greater than zero');
    }
    if (value is num && min is num && max is num) {
      if (value < min || value > max) {
        errors.add('value must be within range');
      }
    }
    if (enabled is! bool) errors.add('enabled must be a boolean');
    return errors.isEmpty
        ? const ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }
}
