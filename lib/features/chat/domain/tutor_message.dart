class TutorMessage {
  const TutorMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
}
