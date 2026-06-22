import '../../language/models/app_language.dart';

/// Roles in a conversation turn.
enum MessageRole {
  /// The student (user).
  student,

  /// The AI tutor.
  assistant,

  /// System-generated messages (errors, status updates).
  system,
}

/// A single message in the conversation history.
class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.language,
    required this.timestamp,
  });

  /// Unique identifier for this message.
  final String id;

  /// Who sent this message.
  final MessageRole role;

  /// The message content (in the target language for display).
  final String text;

  /// The language this message is displayed in.
  final AppLanguage language;

  /// When the message was created.
  final DateTime timestamp;

  @override
  String toString() => 'ConversationMessage($role: $text)';
}
