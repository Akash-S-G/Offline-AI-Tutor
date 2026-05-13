import 'dart:async';

import '../../../config/app_environment.dart';

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
    AppEnvironment.log(
      'WEBSOCKET',
      'Starting stream coordination',
    );
    
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
      if (_active != null) {
        AppEnvironment.log(
          'WEBSOCKET',
          'Stopping active stream',
        );
      }
      await _active?.cancel();
    } catch (e) {
      AppEnvironment.log(
        'WEBSOCKET',
        'Error stopping stream: $e',
      );
    }
    _active = null;
  }

  bool get isActive => _active != null;
}
