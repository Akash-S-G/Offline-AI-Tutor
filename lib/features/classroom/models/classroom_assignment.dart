class ClassroomAssignment {
  final String id;
  final String sessionId;
  final String title;
  final String instructions;
  final DateTime dueDate;
  final List<String> executionModes;
  final List<String> requiredSensors;
  final Map<String, dynamic> manifest;

  ClassroomAssignment({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.instructions,
    required this.dueDate,
    required this.executionModes,
    required this.requiredSensors,
    required this.manifest,
  });
}
