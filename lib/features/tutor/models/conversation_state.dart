/// Full voice conversation lifecycle states.
///
/// This models the end-to-end flow from student speaking
/// through to tutor audio response.
enum ConversationState {
  /// Waiting for student to start speaking.
  idle,

  /// Student is speaking (mic active, audio streaming).
  listening,

  /// Audio recorded, being sent to server.
  uploading,

  /// Server is running ASR on the audio.
  transcribing,

  /// Server is translating (e.g. Kannada → English for LLM).
  translating,

  /// LLM is generating a response.
  thinking,

  /// Server is synthesizing TTS audio.
  generatingAudio,

  /// Tutor response audio is playing.
  speaking,

  /// Something went wrong at any stage.
  error,
}
