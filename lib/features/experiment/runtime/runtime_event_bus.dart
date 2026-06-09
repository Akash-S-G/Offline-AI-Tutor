import 'dart:async';
import 'runtime_event.dart';

class RuntimeEventBus {
  final _controller = StreamController<RuntimeEvent>.broadcast();

  Stream<RuntimeEvent> get stream => _controller.stream;

  void emit(RuntimeEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
