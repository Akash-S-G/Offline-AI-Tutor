import '../../models/runtime_object_state.dart';

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({required this.isValid, this.errors = const []});

  const ValidationResult.valid() : isValid = true, errors = const [];

  const ValidationResult.invalid(this.errors) : isValid = false;
}

abstract class RuntimeObjectBehavior {
  void initialize();

  void onStateUpdated(RuntimeObjectState state);

  ValidationResult validateState(RuntimeObjectState state);

  void dispose();
}

abstract class PlaceholderRuntimeObjectBehavior
    implements RuntimeObjectBehavior {
  RuntimeObjectState? latestState;
  bool initialized = false;

  @override
  void initialize() {
    initialized = true;
  }

  @override
  void onStateUpdated(RuntimeObjectState state) {
    latestState = state;
  }

  @override
  void dispose() {
    initialized = false;
    latestState = null;
  }

  ValidationResult requireFields(
    RuntimeObjectState state,
    List<String> requiredFields,
  ) {
    final missing = requiredFields
        .where((field) => !state.state.containsKey(field))
        .toList(growable: false);
    if (missing.isEmpty) return const ValidationResult.valid();
    return ValidationResult.invalid(
      missing.map((field) => 'Missing required field: $field').toList(),
    );
  }
}
