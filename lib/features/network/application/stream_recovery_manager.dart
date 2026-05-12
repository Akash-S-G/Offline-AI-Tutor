import 'dart:async';

/// Best-effort stream recovery helper.
class StreamRecoveryManager {
  StreamRecoveryManager({this.maxAttempts = 2});

  final int maxAttempts;

  Stream<String> recover(
    Stream<String> Function() streamFactory,
  ) async* {
    Object? lastError;
    for (var attempt = 0; attempt <= maxAttempts; attempt++) {
      try {
        await for (final chunk in streamFactory()) {
          yield chunk;
        }
        return;
      } catch (error) {
        lastError = error;
        if (attempt == maxAttempts) {
          break;
        }
      }
    }
    if (lastError != null) {
      yield 'Stream recovery failed: $lastError';
    }
  }
}
