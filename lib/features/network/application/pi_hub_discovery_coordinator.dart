import 'dart:async';

class PiHubNode {
  const PiHubNode({required this.host, required this.port, required this.name});
  final String host;
  final int port;
  final String name;
}

class PiHubDiscoveryCoordinator {
  PiHubDiscoveryCoordinator();

  final StreamController<List<PiHubNode>> _nodes = StreamController<List<PiHubNode>>.broadcast();
  List<PiHubNode> _current = const [];

  Stream<List<PiHubNode>> get discoveryUpdates => _nodes.stream;
  List<PiHubNode> get currentNodes => _current;

  Future<void> scan() async {
    // Placeholder discovery: local classroom coordinator can inject nodes later.
    _current = <PiHubNode>[_current.firstOrNull ?? const PiHubNode(host: '127.0.0.1', port: 8080, name: 'Local PiHub')];
    _nodes.add(_current);
  }

  Future<void> registerDevice({required String deviceId}) async {
    // Registration will be routed to the active node in a later phase.
    if (_current.isEmpty) {
      await scan();
    }
  }

  Future<void> close() async {
    await _nodes.close();
  }
}

extension _FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
