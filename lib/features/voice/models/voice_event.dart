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
    this.language,
    this.sequence,
    this.data,
  });

  /// Event kind. One of the values in [VoiceEventType].
  final String type;

  /// Event-specific data (may be empty for status-only events).
  final Map<String, dynamic> payload;

  final String? sessionId;
  final String? deviceId;
  final String? studentId;
  final String? language;
  
  final int? sequence;
  final String? data;

  /// Deserialize a JSON map from the WebSocket.
  factory VoiceEvent.fromJson(Map<String, dynamic> json) {
    return VoiceEvent(
      type: json['type'] as String? ?? 'unknown',
      payload: json['payload'] as Map<String, dynamic>? ?? const {},
      sessionId: json['session_id'] as String?,
      deviceId: json['device_id'] as String?,
      studentId: json['student_id'] as String?,
      language: json['language'] as String?,
      sequence: json['sequence'] as int?,
      data: json['data'] as String?,
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
    if (language != null) map['language'] = language;
    if (sequence != null) map['sequence'] = sequence;
    if (data != null) map['data'] = data;
    return map;
  }

  @override
  String toString() => 'VoiceEvent($type, seq: $sequence, data: ${data != null}, payload: $payload)';
}

/// Well-known event type constants.
abstract final class VoiceEventType {
  static const connected = 'connected';
  static const sessionAcknowledged = 'session_acknowledged';
  static const partialTranscript = 'partial_transcript';
  static const finalTranscript = 'final_transcript';
  static const transcribing = 'transcribing';
  static const thinking = 'thinking';
  static const generatingAudio = 'generating_audio';
  static const assistantMessage = 'assistant_message';
  static const audioChunk = 'audio_chunk';
  static const responseChunk = 'response_chunk';
  static const responseComplete = 'response_complete';
  static const error = 'error';

  // Client → Server
  static const sessionStart = 'session_start';
  static const audioStart = 'audio_start';
  static const audioData = 'audio_data';
  static const audioComplete = 'audio_complete';
}
