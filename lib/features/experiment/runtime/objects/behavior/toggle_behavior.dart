import '../../models/runtime_object_state.dart';
import 'runtime_object_behavior.dart';

class ToggleBehavior extends PlaceholderRuntimeObjectBehavior {
  @override
  ValidationResult validateState(RuntimeObjectState state) {
    final errors = <String>[];
    if (state.state['value'] is! bool) {
      errors.add('value must be a boolean');
    }
    if (state.state['enabled'] is! bool) {
      errors.add('enabled must be a boolean');
    }
    return errors.isEmpty
        ? const ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }
}
