import 'dart:async';

/// Coordinates local and backend streams, supports handoff and cancellation.
class StreamCoordinator {
  StreamCoordinator();

  StreamSubscription<String>? _active;

  /// Start listening to a stream and forward chunks to `onChunk`.
  Future<void> startStream(
    Stream<String> stream,
    void Function(String chunk) onChunk,
    void Function()? onDone,
    void Function(Object error)? onError,
  ) async {
    await stopActive();
    _active = stream.listen(
      onChunk,
      onError: onError,
      onDone: onDone,
      cancelOnError: true,
    );
  }

  Future<void> stopActive() async {
    try {
      await _active?.cancel();
    } catch (_) {}
    _active = null;
  }

  bool get isActive => _active != null;
}
