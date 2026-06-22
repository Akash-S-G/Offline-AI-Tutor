class SessionInfo {
  const SessionInfo({
    required this.sessionId,
    required this.deviceId,
    required this.studentId,
  });

  final String sessionId;
  final String deviceId;
  final String studentId;

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'device_id': deviceId,
      'student_id': studentId,
    };
  }

  SessionInfo copyWith({
    String? sessionId,
    String? deviceId,
    String? studentId,
  }) {
    return SessionInfo(
      sessionId: sessionId ?? this.sessionId,
      deviceId: deviceId ?? this.deviceId,
      studentId: studentId ?? this.studentId,
    );
  }
}
