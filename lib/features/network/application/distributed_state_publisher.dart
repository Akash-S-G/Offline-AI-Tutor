import 'dart:async';

import 'connectivity_state_coordinator.dart';

class DistributedStatePublisher {
  final StreamController<ConnectivityStateSnapshot> _controller = StreamController<ConnectivityStateSnapshot>.broadcast();

  Stream<ConnectivityStateSnapshot> get stream => _controller.stream;

  void publish(ConnectivityStateSnapshot snapshot) {
    _controller.add(snapshot);
  }

  Future<void> close() => _controller.close();
}
