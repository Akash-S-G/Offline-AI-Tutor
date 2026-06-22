/// Voice pipeline states.
///
/// These represent what the local audio subsystem is doing —
/// NOT the conversation state (that's in `tutor/`).
enum VoiceState {
  /// Mic idle, ready to record.
  idle,

  /// Actively recording audio from microphone.
  listening,

  /// Audio recorded, being processed locally (encoding, etc.).
  processing,

  /// Playing back audio (tutor response or recording preview).
  speaking,

  /// An error occurred (permission denied, device error, etc.).
  error,
}
