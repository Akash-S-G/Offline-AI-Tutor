import 'package:flutter/foundation.dart';

import '../../voice/models/voice_event.dart';
import '../providers/language_provider.dart';

/// Intercepts VoiceEvents to ensure language consistency between
/// the UI and the backend payload contract.
class LanguageInterceptor {
  LanguageInterceptor(this.languageProvider);

  final LanguageProvider languageProvider;

  /// Attaches the current UI language code to an outgoing event.
  VoiceEvent interceptOutgoing(VoiceEvent event) {
    return VoiceEvent(
      type: event.type,
      payload: event.payload,
      sessionId: event.sessionId,
      deviceId: event.deviceId,
      studentId: event.studentId,
      language: languageProvider.languageCode,
    );
  }

  /// Validates an incoming event's language payload against the current UI language.
  /// Logs a warning if there is a mismatch. Returns true if valid or warning logged.
  bool validateIncoming(VoiceEvent event) {
    if (event.type == VoiceEventType.assistantMessage ||
        event.type == VoiceEventType.finalTranscript) {
      final payloadLang = event.payload['language'] as String?;
      if (payloadLang != null && payloadLang != languageProvider.languageCode) {
        debugPrint(
          'WARNING (LanguageInterceptor): Mismatched language! '
          'Expected ${languageProvider.languageCode}, got $payloadLang.',
        );
        // Returning true because we still want to process the message,
        // it's just a warning.
      }
    }
    return true;
  }
}
