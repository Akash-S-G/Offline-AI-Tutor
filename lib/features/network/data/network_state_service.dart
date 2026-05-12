import 'dart:async';

import 'connectivity_service.dart';

/// Network quality indicators.
enum NetworkQuality {
  /// No connectivity
  offline,

  /// Online but backend unreachable
  online,

  /// Backend reachable with high latency (>500ms)
  slowBackend,

  /// Backend reachable with acceptable latency (100-500ms)
  moderateBackend,

  /// Backend reachable with low latency (<100ms)
  fastBackend,
}

/// Manages network state with periodic updates.
class NetworkStateService {
  NetworkStateService({
    required ConnectivityService connectivityService,
    required String backendUrl,
    this.pollIntervalSeconds = 30,
  })  : _connectivityService = connectivityService,
        _backendUrl = backendUrl,
        _snapshots = StreamController<ConnectivitySnapshot>.broadcast();

  final ConnectivityService _connectivityService;
  final String _backendUrl;
  final int pollIntervalSeconds;
  final StreamController<ConnectivitySnapshot> _snapshots;

  Timer? _timer;
  ConnectivitySnapshot? _lastSnapshot;

  /// Stream of connectivity snapshots
  Stream<ConnectivitySnapshot> get snapshots => _snapshots.stream;

  /// Get current snapshot
  ConnectivitySnapshot? get currentSnapshot => _lastSnapshot;

  /// Get current network quality
  NetworkQuality get quality {
    final snapshot = _lastSnapshot;
    if (snapshot == null) {
      return NetworkQuality.offline;
    }
    if (!snapshot.isOnline) {
      return NetworkQuality.offline;
    }
    if (!snapshot.hasBackend) {
      return NetworkQuality.online;
    }

    final latency = snapshot.backendLatencyMs ?? 0;
    if (latency > 500) {
      return NetworkQuality.slowBackend;
    } else if (latency > 100) {
      return NetworkQuality.moderateBackend;
    } else {
      return NetworkQuality.fastBackend;
    }
  }

  /// Start monitoring connectivity
  Future<void> start() async {
    // Initial check
    await _refresh();

    // Periodic refresh
    _timer = Timer.periodic(
      Duration(seconds: pollIntervalSeconds),
      (_) => _refresh(),
    );
  }

  /// Stop monitoring
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Force immediate refresh
  Future<void> refresh() async {
    await _refresh();
  }

  /// Perform connectivity check
  Future<void> _refresh() async {
    try {
      final snapshot = await _connectivityService.getSnapshot(
        backendUrl: _backendUrl,
      );
      _lastSnapshot = snapshot;
      _snapshots.add(snapshot);
    } catch (_) {
      // Swallow errors during polling
    }
  }

  /// Close the service
  void close() {
    stop();
    _snapshots.close();
  }
}
