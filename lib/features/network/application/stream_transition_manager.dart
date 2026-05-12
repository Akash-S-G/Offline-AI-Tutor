import 'dart:async';

/// Handles transitions between local and backend streams.
class StreamTransitionManager {
  StreamTransitionManager({this.transitionWindow = const Duration(milliseconds: 120)});

  final Duration transitionWindow;

  Stream<String> upgradeStream({
    required Stream<String> primary,
    required Stream<String> secondary,
  }) async* {
    final buffer = StringBuffer();
    await for (final chunk in primary) {
      buffer.write(chunk);
      yield chunk;
    }
    await Future<void>.delayed(transitionWindow);
    await for (final chunk in secondary) {
      yield chunk;
    }
  }
}
