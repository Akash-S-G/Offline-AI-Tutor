class RuntimeObjectSchema {
  final String objectType;
  final Map<String, dynamic> defaultState;
  final List<String> requiredFields;
  final List<String> optionalFields;

  const RuntimeObjectSchema({
    required this.objectType,
    required this.defaultState,
    required this.requiredFields,
    required this.optionalFields,
  });

  Map<String, dynamic> applyDefaults(Map<String, dynamic> state) {
    return {...defaultState, ...state};
  }
}
