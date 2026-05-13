import 'dart:async';
import '../../../config/app_environment.dart';

class PiHubNode {
  const PiHubNode({required this.host, required this.port, required this.name});
  final String host;
  final int port;
  final String name;

  @override
  String toString() => 'PiHubNode(host=$host, port=$port, name=$name)';
}

class PiHubDiscoveryCoordinator {
  PiHubDiscoveryCoordinator() {
    _initializeDefaultNode();
  }

  final StreamController<List<PiHubNode>> _nodes = StreamController<List<PiHubNode>>.broadcast();
  List<PiHubNode> _current = const [];

  Stream<List<PiHubNode>> get discoveryUpdates => _nodes.stream;
  List<PiHubNode> get currentNodes => _current;

  /// Initialize with default PiHub node from environment configuration
  void _initializeDefaultNode() {
    try {
      // Extract host and port from AppEnvironment
      final piHubUrl = AppEnvironment.piHubUrl;
      final piHubPort = AppEnvironment.pihubPort;
      
      // Parse host from URL (e.g., "http://172.17.13.112:8080" -> "172.17.13.112")
      final uri = Uri.parse(piHubUrl);
      final host = uri.host.isNotEmpty ? uri.host : '172.17.13.112';
      final port = piHubPort;

      _current = [
        PiHubNode(
          host: host,
          port: port,
          name: 'PiHub (${AppEnvironment.deploymentMode})',
        ),
      ];

      AppEnvironment.log(
        'DISCOVERY',
        'PiHub initialized: $host:$port',
      );
    } catch (e) {
      AppEnvironment.log(
        'DISCOVERY',
        'Failed to initialize PiHub: $e',
      );
      // Fallback to localhost
      _current = [
        const PiHubNode(host: '127.0.0.1', port: 8080, name: 'Local PiHub (fallback)'),
      ];
    }
  }

  Future<void> scan() async {
    AppEnvironment.log(
      'DISCOVERY',
      'Scanning for PiHub nodes...',
    );
    
    // If already initialized, use current nodes
    if (_current.isNotEmpty) {
      _nodes.add(_current);
      return;
    }

    // Initialize default node if not already done
    _initializeDefaultNode();
    _nodes.add(_current);
  }

  Future<void> registerDevice({required String deviceId}) async {
    AppEnvironment.log(
      'DISCOVERY',
      'Registering device: $deviceId',
    );
    
    // Registration will be routed to the active node in a later phase.
    if (_current.isEmpty) {
      await scan();
    }
  }

  Future<void> close() async {
    await _nodes.close();
  }
}
