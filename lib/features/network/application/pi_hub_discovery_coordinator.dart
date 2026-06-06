import 'dart:async';
import 'dart:io';
import '../../../config/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PiHubNode {
  const PiHubNode({required this.host, required this.port, required this.name});
  final String host;
  final int port;
  final String name;

  String get baseUrl => 'http://$host${port == 80 ? '' : ':$port'}';

  @override
  String toString() => 'PiHubNode(host=$host, port=$port, name=$name)';
}

/// Production PiHub Discovery Coordinator.
///
/// Discovery flow:
///   1. Load last-known-good IP from persistent cache
///   2. Health check cached IP
///   3. If healthy → use immediately
///   4. If unreachable → scan LAN subnet for PiHub nodes
///   5. Health-check each candidate
///   6. Select fastest healthy node
///   7. Persist discovered IP
///   8. Notify listeners
class PiHubDiscoveryCoordinator {
  PiHubDiscoveryCoordinator() {
    _initializeDefaultNode();
  }

  final StreamController<List<PiHubNode>> _nodes = StreamController<List<PiHubNode>>.broadcast();
  List<PiHubNode> _current = const [];
  bool _isScanning = false;

  Stream<List<PiHubNode>> get discoveryUpdates => _nodes.stream;
  List<PiHubNode> get currentNodes => _current;
  bool get isScanning => _isScanning;

  /// Best known PiHub node (first in the list).
  PiHubNode? get bestNode => _current.isNotEmpty ? _current.first : null;

  static const _cacheKey = 'pihub_last_known_ip';
  static const _cachePortKey = 'pihub_last_known_port';
  static const _healthPath = '/health';
  static const _scanTimeoutMs = 500;
  static const _healthTimeoutMs = 2000;

  /// Initialize with default node from .env (seed IP).
  void _initializeDefaultNode() {
    try {
      final backendUrl = AppEnvironment.backendBaseUrl;
      final uri = Uri.parse(backendUrl);
      final host = uri.host.isNotEmpty ? uri.host : '10.28.73.193';
      final port = uri.hasPort ? uri.port : 80;

      _current = [
        PiHubNode(
          host: host,
          port: port,
          name: 'PiHub Gateway (seed)',
        ),
      ];

      print('[DISCOVERY] INITIALIZED host=$host port=$port source=env');
    } catch (e) {
      print('[DISCOVERY] INIT_ERROR=$e');
      final uri = Uri.parse(AppEnvironment.backendBaseUrl);
      _current = [
        PiHubNode(host: uri.host, port: 80, name: 'PiHub Gateway (fallback)'),
      ];
    }
  }

  /// Full discovery flow:
  ///   cached IP → health check → LAN scan → health validate → select best
  Future<PiHubNode?> discover() async {
    if (_isScanning) {
      print('[DISCOVERY] ALREADY_SCANNING — skipping');
      return bestNode;
    }
    _isScanning = true;
    print('[DISCOVERY] SCAN_START');

    try {
      // Step 1: Try cached IP
      final cached = await _loadCachedNode();
      if (cached != null) {
        print('[DISCOVERY] CACHED_IP=${cached.host}');
        if (await _healthCheck(cached)) {
          print('[DISCOVERY] CACHED_IP_HEALTHY=true');
          _updateNodes([cached]);
          return cached;
        }
        print('[DISCOVERY] CACHED_IP_HEALTHY=false');
      }

      // Step 2: Try seed IP from .env
      if (_current.isNotEmpty) {
        final seed = _current.first;
        print('[DISCOVERY] SEED_IP=${seed.host}');
        if (await _healthCheck(seed)) {
          print('[DISCOVERY] SEED_IP_HEALTHY=true');
          await _persistNode(seed);
          _updateNodes([seed]);
          return seed;
        }
        print('[DISCOVERY] SEED_IP_HEALTHY=false');
      }

      // Step 3: LAN subnet scan
      final candidates = await _scanSubnet();
      if (candidates.isEmpty) {
        print('[DISCOVERY] NO_CANDIDATES_FOUND');
        return bestNode;
      }

      // Step 4: Health check each candidate
      for (final candidate in candidates) {
        print('[DISCOVERY] CANDIDATE=${candidate.host}');
        if (await _healthCheck(candidate)) {
          print('[DISCOVERY] HEALTHY=${candidate.host}');
          await _persistNode(candidate);
          _updateNodes([candidate]);
          return candidate;
        }
      }

      print('[DISCOVERY] NO_HEALTHY_NODES_FOUND');
      return bestNode;
    } finally {
      _isScanning = false;
    }
  }

  /// Legacy scan() method — now delegates to full discover().
  Future<void> scan() async {
    await discover();
  }

  Future<void> registerDevice({required String deviceId}) async {
    AppEnvironment.log('DISCOVERY', 'Registering device: $deviceId');
    if (_current.isEmpty) {
      await scan();
    }
  }

  /// Scan the local /24 subnet for hosts with an open HTTP port.
  Future<List<PiHubNode>> _scanSubnet() async {
    print('[DISCOVERY] SUBNET_SCAN_START');
    final baseIp = _getSubnetBase();
    if (baseIp == null) {
      print('[DISCOVERY] SUBNET_SCAN_FAILED (no network interface)');
      return [];
    }

    print('[DISCOVERY] SUBNET_BASE=$baseIp');
    final candidates = <PiHubNode>[];
    final futures = <Future<void>>[];

    // Scan .1 to .254 in parallel batches
    for (int i = 1; i <= 254; i++) {
      final ip = '$baseIp.$i';
      futures.add(_probeHost(ip, 80).then((alive) {
        if (alive) {
          candidates.add(PiHubNode(host: ip, port: 80, name: 'LAN-$ip'));
        }
      }));
    }

    await Future.wait(futures);
    print('[DISCOVERY] SUBNET_SCAN_END candidates=${candidates.length}');
    return candidates;
  }

  /// Probe a single host:port with a TCP connect timeout.
  Future<bool> _probeHost(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(milliseconds: _scanTimeoutMs),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Health check a PiHub node via GET /health.
  Future<bool> _healthCheck(PiHubNode node) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = Duration(milliseconds: _healthTimeoutMs);
      final uri = Uri.parse('http://${node.host}:${node.port}$_healthPath');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        Duration(milliseconds: _healthTimeoutMs),
      );
      client.close(force: true);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Get the /24 subnet base from the device's network interfaces.
  String? _getSubnetBase() {
    try {
      final interfaces = NetworkInterface.list(type: InternetAddressType.IPv4);
      // We'll use the seed IP's subnet as the scan base
      if (_current.isNotEmpty) {
        final parts = _current.first.host.split('.');
        if (parts.length == 4) {
          return '${parts[0]}.${parts[1]}.${parts[2]}';
        }
      }
    } catch (_) {}
    return null;
  }

  void _updateNodes(List<PiHubNode> nodes) {
    _current = nodes;
    _nodes.add(nodes);
    if (nodes.isNotEmpty) {
      print('[DISCOVERY] URL_UPDATED=${nodes.first.baseUrl}');
    }
  }

  /// Persist last-known-good node to SharedPreferences.
  Future<void> _persistNode(PiHubNode node) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, node.host);
      await prefs.setInt(_cachePortKey, node.port);
      print('[DISCOVERY] PERSISTED ip=${node.host} port=${node.port}');
    } catch (e) {
      print('[DISCOVERY] PERSIST_ERROR=$e');
    }
  }

  /// Load last-known-good node from SharedPreferences.
  Future<PiHubNode?> _loadCachedNode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString(_cacheKey);
      final port = prefs.getInt(_cachePortKey) ?? 80;
      if (ip != null && ip.isNotEmpty) {
        return PiHubNode(host: ip, port: port, name: 'PiHub (cached)');
      }
    } catch (e) {
      print('[DISCOVERY] CACHE_LOAD_ERROR=$e');
    }
    return null;
  }

  Future<void> close() async {
    await _nodes.close();
  }
}
