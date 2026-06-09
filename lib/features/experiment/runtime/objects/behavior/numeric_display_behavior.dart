import '../../models/runtime_object_state.dart';
import 'runtime_object_behavior.dart';

class NumericDisplayBehavior extends PlaceholderRuntimeObjectBehavior {
  @override
  ValidationResult validateState(RuntimeObjectState state) {
    return requireFields(state, ['value']);
  }
}
