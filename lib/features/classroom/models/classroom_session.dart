class ClassroomSession {
  final String id;
  final String topic;
  final String teacherName;
  final bool isActive;
  final List<String> connectedStudents;

  ClassroomSession({
    required this.id,
    required this.topic,
    required this.teacherName,
    this.isActive = true,
    this.connectedStudents = const [],
  });

  ClassroomSession copyWith({
    String? id,
    String? topic,
    String? teacherName,
    bool? isActive,
    List<String>? connectedStudents,
  }) {
    return ClassroomSession(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      teacherName: teacherName ?? this.teacherName,
      isActive: isActive ?? this.isActive,
      connectedStudents: connectedStudents ?? this.connectedStudents,
    );
  }
}
