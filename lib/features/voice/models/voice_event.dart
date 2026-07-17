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
  ///
  /// The backend sends event-specific data as top-level keys (e.g. `"text"`,
  /// `"confidence"`, `"message"`) rather than nesting them under `"payload"`.
  /// We merge those top-level keys into [payload] so all call sites that read
  /// `event.payload['text']` continue to work without changes.
  factory VoiceEvent.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? 'unknown';

    // Start with any explicit nested payload the server may include.
    final merged = <String, dynamic>{
      ...((json['payload'] as Map?)?.cast<String, dynamic>() ?? {}),
    };
    // Pull backend top-level text fields into payload.
    for (final key in const ['text', 'confidence', 'message']) {
      if (json.containsKey(key) && !merged.containsKey(key)) {
        merged[key] = json[key];
      }
    }

    return VoiceEvent(
      type: _normalizeType(rawType),
      payload: merged.isEmpty ? const <String, dynamic>{} : Map.unmodifiable(merged),
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

  static String _normalizeType(String type) {
    return switch (type) {
      // Backward compatibility with older voice routes.
      'audio_data' => VoiceEventType.audioChunk,
      'audio_start' => VoiceEventType.sessionStart,
      _ => type,
    };
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
