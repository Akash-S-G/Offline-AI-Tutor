class ClassroomSubmission {
  final String id;
  final String assignmentId;
  final String studentName;
  final String status; // e.g. "Completed", "Pending", "Failed"
  final DateTime completionTime;
  final DateTime submissionTime;
  final Map<String, dynamic> resultMetrics;

  ClassroomSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentName,
    required this.status,
    required this.completionTime,
    required this.submissionTime,
    this.resultMetrics = const {},
  });
}
