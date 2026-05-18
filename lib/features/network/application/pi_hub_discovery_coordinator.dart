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
      // Extract host from BACKEND_BASE_URL
      final backendUrl = AppEnvironment.backendBaseUrl;
      final uri = Uri.parse(backendUrl);
      final host = uri.host.isNotEmpty ? uri.host : '10.28.73.193';
      
      // All PiHub communication now goes through nginx gateway on standard ports
      // The gateway routes /classroom/* endpoints to the appropriate service
      final port = 80; // nginx gateway standard port

      _current = [
        PiHubNode(
          host: host,
          port: port,
          name: 'PiHub Gateway (${AppEnvironment.deploymentMode})',
        ),
      ];

      AppEnvironment.log(
        'DISCOVERY',
        'PiHub discovery initialized: $host:$port (via nginx gateway)',
      );
    } catch (e) {
      AppEnvironment.log(
        'DISCOVERY',
        'Failed to initialize PiHub discovery: $e',
      );
      // Fallback to configured gateway
      final uri = Uri.parse(AppEnvironment.backendBaseUrl);
      _current = [
        PiHubNode(
          host: uri.host,
          port: 80,
          name: 'PiHub Gateway (fallback)',
        ),
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
