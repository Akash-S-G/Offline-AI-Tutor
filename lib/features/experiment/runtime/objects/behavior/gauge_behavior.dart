import '../../models/runtime_object_state.dart';
import 'runtime_object_behavior.dart';

class GaugeBehavior extends PlaceholderRuntimeObjectBehavior {
  @override
  ValidationResult validateState(RuntimeObjectState state) {
    final errors = <String>[];
    errors.addAll(requireFields(state, ['value']).errors);
    final min = state.state['min'];
    final max = state.state['max'];
    final value = state.state['value'];
    if (min is num && max is num && min >= max) {
      errors.add('min must be less than max');
    }
    if (value is num && min is num && max is num) {
      if (value < min || value > max) {
        errors.add('value must be within min and max');
      }
    }
    return errors.isEmpty
        ? const ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }
}
