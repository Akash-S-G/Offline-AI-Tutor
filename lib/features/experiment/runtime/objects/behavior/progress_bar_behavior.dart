import '../../models/runtime_object_state.dart';
import 'runtime_object_behavior.dart';

class ProgressBarBehavior extends PlaceholderRuntimeObjectBehavior {
  @override
  ValidationResult validateState(RuntimeObjectState state) {
    final errors = <String>[];
    errors.addAll(requireFields(state, ['value']).errors);
    final min = state.state['min'];
    final max = state.state['max'];
    if (min is num && max is num && min >= max) {
      errors.add('min must be less than max');
    }
    return errors.isEmpty
        ? const ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }
}
