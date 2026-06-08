import 'dart:async';
import '../domain/runtime_backend_url.dart';
import 'backend_url_manager.dart';
import 'connectivity_controller.dart';
import 'pi_hub_discovery_coordinator.dart';

/// Bridges PiHub discovery events to automatic sync and URL updates.
///
/// Flow:
///   Discovery finds healthy PiHub
///       ↓
///   BackendUrlManager.updateUrl(...)
///       ↓
///   ConnectivityController.goOnline(...)
///       ↓
///   Trigger sync callback
///
/// Debounces reconnect storms: max one sync per discovery event,
/// minimum 30 seconds between auto-syncs.
class DiscoverySyncBridge {
  DiscoverySyncBridge({
    required PiHubDiscoveryCoordinator discovery,
    required BackendUrlManager urlManager,
    required ConnectivityController connectivity,
    Future<void> Function()? onSyncRequested,
  })  : _discovery = discovery,
        _urlManager = urlManager,
        _connectivity = connectivity,
        _onSyncRequested = onSyncRequested;

  final PiHubDiscoveryCoordinator _discovery;
  final BackendUrlManager _urlManager;
  final ConnectivityController _connectivity;
  final Future<void> Function()? _onSyncRequested;

  StreamSubscription<List<PiHubNode>>? _subscription;
  bool _syncInProgress = false;
  DateTime? _lastSyncAt;
  static const _minSyncInterval = Duration(seconds: 30);

  /// Start listening for discovery events.
  void start() {
    _subscription = _discovery.discoveryUpdates.listen(_onNodesDiscovered);
    print('[SYNC] DiscoverySyncBridge started');
  }

  void _onNodesDiscovered(List<PiHubNode> nodes) async {
    if (nodes.isEmpty) {
      print('[SYNC] DISCOVERY_EVENT nodes=0 → staying offline');
      _connectivity.goOffline();
      return;
    }

    final best = nodes.first;
    print('[SYNC] DISCOVERY_TRIGGERED node=${best.host}:${best.port}');

    // Update the backend URL
    _urlManager.updateUrl(best.baseUrl);
    _connectivity.goOnline(best.baseUrl);

    // Give synchronous streams a tiny microtask to propagate URL
    await Future.microtask(() {});

    // Verification Harness
    final runtimeUrl = RuntimeBackendUrl().current;
    final syncUrl = '$runtimeUrl/packs/sync';
    final healthUrl = '$runtimeUrl/health';
    final downloadUrl = '$runtimeUrl/packs/{id}/download';
    
    print('[VERIFY] ACTIVE_BACKEND=$runtimeUrl');
    print('[VERIFY] ACTIVE_SYNC_URL=$syncUrl');
    print('[VERIFY] ACTIVE_HEALTH_URL=$healthUrl');
    print('[VERIFY] ACTIVE_DOWNLOAD_URL=$downloadUrl');

    final expectedHost = Uri.parse(best.baseUrl).host;
    final rUri = Uri.parse(runtimeUrl);
    final sUri = Uri.parse(syncUrl);
    final hUri = Uri.parse(healthUrl);
    final dUri = Uri.parse(downloadUrl);

    if (rUri.host != expectedHost || sUri.host != expectedHost || hUri.host != expectedHost || dUri.host != expectedHost) {
      print('[VERIFY] URL_PROPAGATION_FAILURE');
    }

    // Debounce: skip if we synced recently
    if (_lastSyncAt != null &&
        DateTime.now().difference(_lastSyncAt!) < _minSyncInterval) {
      print('[SYNC] DEBOUNCED (last sync ${DateTime.now().difference(_lastSyncAt!).inSeconds}s ago)');
      return;
    }

    // Skip if sync already in progress
    if (_syncInProgress) {
      print('[SYNC] SKIPPED (sync already in progress)');
      return;
    }

    // Trigger sync
    if (_onSyncRequested != null) {
      _syncInProgress = true;
      _connectivity.startSync();
      print('[SYNC] PACK_SYNC_START');
      try {
        await _onSyncRequested!();
        _lastSyncAt = DateTime.now();
        print('[SYNC] PACK_SYNC_END');
      } catch (e) {
        print('[SYNC] PACK_SYNC_ERROR=$e');
      } finally {
        _syncInProgress = false;
        _connectivity.finishSync();
      }
    }
  }

  /// Manually trigger discovery + sync.
  Future<void> discoverAndSync() async {
    _connectivity.startDiscovery();
    final node = await _discovery.discover();
    if (node != null) {
      _onNodesDiscovered([node]);
    } else {
      _connectivity.goOffline();
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
