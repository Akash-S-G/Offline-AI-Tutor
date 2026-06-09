import 'dart:async';

import '../runtime_event_bus.dart';
import 'runtime_interaction_event.dart';

class RuntimeInteractionBus {
  final RuntimeEventBus runtimeEventBus;
  final StreamController<RuntimeInteractionEvent> _controller =
      StreamController<RuntimeInteractionEvent>.broadcast();

  RuntimeInteractionBus({required this.runtimeEventBus});

  Stream<RuntimeInteractionEvent> get stream => _controller.stream;

  void emit(RuntimeInteractionEvent event) {
    _controller.add(event);
    runtimeEventBus.emit(event.toRuntimeEvent());
  }

  void dispose() {
    _controller.close();
  }
}
