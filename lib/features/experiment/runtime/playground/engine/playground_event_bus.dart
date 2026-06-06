import 'dart:async';
import '../models/playground_event.dart';

class PlaygroundEventBus {
  final StreamController<PlaygroundEvent> _controller = StreamController<PlaygroundEvent>.broadcast();

  Stream<PlaygroundEvent> get stream => _controller.stream;

  void publish(PlaygroundEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
