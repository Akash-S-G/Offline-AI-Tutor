/// An event received from (or sent to) the voice WebSocket.
///
/// The [type] field identifies the event kind; [payload] carries
/// the event-specific data.
class VoiceEvent {
  const VoiceEvent({
    required this.type,
    this.payload = const <String, dynamic>{},
    this.sessionId,
    this.deviceId,
    this.studentId,
  });

  /// Event kind. One of the values in [VoiceEventType].
  final String type;

  /// Event-specific data (may be empty for status-only events).
  final Map<String, dynamic> payload;

  final String? sessionId;
  final String? deviceId;
  final String? studentId;

  /// Deserialize a JSON map from the WebSocket.
  factory VoiceEvent.fromJson(Map<String, dynamic> json) {
    return VoiceEvent(
      type: json['type'] as String? ?? 'unknown',
      payload: json['payload'] as Map<String, dynamic>? ?? const {},
      sessionId: json['session_id'] as String?,
      deviceId: json['device_id'] as String?,
      studentId: json['student_id'] as String?,
    );
  }

  /// Serialize for sending over the WebSocket.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': type,
      if (payload.isNotEmpty) 'payload': payload,
    };
    if (sessionId != null) map['session_id'] = sessionId;
    if (deviceId != null) map['device_id'] = deviceId;
    if (studentId != null) map['student_id'] = studentId;
    return map;
  }

  @override
  String toString() => 'VoiceEvent($type, $payload)';
}

/// Well-known event type constants.
abstract final class VoiceEventType {
  static const connected = 'connected';
  static const partialTranscript = 'partial_transcript';
  static const finalTranscript = 'final_transcript';
  static const assistantMessage = 'assistant_message';
  static const audioChunk = 'audio_chunk';
  static const error = 'error';

  // Client → Server
  static const audioData = 'audio_data';
  static const audioComplete = 'audio_complete';
}
