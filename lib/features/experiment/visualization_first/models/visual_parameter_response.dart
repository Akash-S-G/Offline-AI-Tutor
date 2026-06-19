class VisualParameterResponse {
  final String variableSemanticId;
  final String targetId;
  final String affectedProperty;
  final String responseDescription;
  final Map<String, dynamic> transform;

  const VisualParameterResponse({
    required this.variableSemanticId,
    required this.targetId,
    required this.affectedProperty,
    required this.responseDescription,
    this.transform = const {},
  });

  bool get isValid {
    return variableSemanticId.isNotEmpty &&
        targetId.isNotEmpty &&
        affectedProperty.isNotEmpty &&
        responseDescription.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'variableSemanticId': variableSemanticId,
      'targetId': targetId,
      'affectedProperty': affectedProperty,
      'responseDescription': responseDescription,
      'transform': transform,
    };
  }
}
