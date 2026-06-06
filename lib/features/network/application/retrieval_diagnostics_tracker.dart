import 'package:flutter/foundation.dart';

/// Tracks the latest retrieval diagnostics for the hidden debugging screen.
class RetrievalDiagnosticsTracker extends ChangeNotifier {
  static final RetrievalDiagnosticsTracker instance = RetrievalDiagnosticsTracker._();

  RetrievalDiagnosticsTracker._();

  String normalizedTopic = '';
  String detectedIntent = '';
  int chunksFound = 0;
  String retrievalMode = '';
  String fallbackReason = '';
  String executionMode = '';

  void update({
    String? topic,
    String? intent,
    int? chunks,
    String? mode,
    String? fallback,
    String? execMode,
  }) {
    if (topic != null) normalizedTopic = topic;
    if (intent != null) detectedIntent = intent;
    if (chunks != null) chunksFound = chunks;
    if (mode != null) retrievalMode = mode;
    if (fallback != null) fallbackReason = fallback;
    if (execMode != null) executionMode = execMode;
    notifyListeners();
  }
}
