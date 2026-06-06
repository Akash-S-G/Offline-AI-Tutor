import 'dart:async';
import 'package:flutter/foundation.dart';

/// The application's connectivity state.
enum ConnectivityMode {
  /// No PiHub reachable. Fully local inference only.
  offline,

  /// Actively scanning LAN for PiHub nodes.
  discovering,

  /// Healthy PiHub connection established.
  online,

  /// Currently syncing packs / progress with PiHub.
  syncing,
}

/// Single source of truth for online/offline state.
///
/// Aggregates signals from:
///   - BackendHealthMonitor
///   - PiHubDiscoveryCoordinator
///   - SyncManager
///
/// Exposes a [ValueNotifier] so any widget can react to transitions.
class ConnectivityController extends ChangeNotifier {
  ConnectivityController() {
    print('[CONNECTIVITY] ConnectivityController initialized: ${_mode.name}');
  }

  ConnectivityMode _mode = ConnectivityMode.offline;
  DateTime? _lastTransition;
  String? _activeBackendUrl;

  /// Current connectivity mode.
  ConnectivityMode get mode => _mode;

  /// Whether the system has any backend connection.
  bool get isOnline => _mode == ConnectivityMode.online || _mode == ConnectivityMode.syncing;

  /// Whether active sync is in progress.
  bool get isSyncing => _mode == ConnectivityMode.syncing;

  /// Whether discovery scan is in progress.
  bool get isDiscovering => _mode == ConnectivityMode.discovering;

  /// Time of last state transition.
  DateTime? get lastTransition => _lastTransition;

  /// Active backend URL (null if offline).
  String? get activeBackendUrl => _activeBackendUrl;

  /// Transition to a new connectivity mode.
  void transitionTo(ConnectivityMode newMode, {String? backendUrl}) {
    if (newMode == _mode) return;

    final previous = _mode;
    _mode = newMode;
    _lastTransition = DateTime.now();

    if (backendUrl != null) {
      _activeBackendUrl = backendUrl;
    }

    print('[CONNECTIVITY] TRANSITION ${previous.name} → ${newMode.name}');
    if (backendUrl != null) {
      print('[CONNECTIVITY] BACKEND_URL=$backendUrl');
    }

    notifyListeners();
  }

  /// Convenience methods for common transitions.
  void goOnline(String backendUrl) => transitionTo(ConnectivityMode.online, backendUrl: backendUrl);
  void goOffline() {
    _activeBackendUrl = null;
    transitionTo(ConnectivityMode.offline);
  }
  void startDiscovery() => transitionTo(ConnectivityMode.discovering);
  void startSync() => transitionTo(ConnectivityMode.syncing);
  void finishSync() => transitionTo(ConnectivityMode.online);

  /// Human-readable status for UI display.
  String get statusLabel {
    switch (_mode) {
      case ConnectivityMode.offline:
        return 'Offline — Using local AI';
      case ConnectivityMode.discovering:
        return 'Searching for PiHub...';
      case ConnectivityMode.online:
        return 'Connected to PiHub';
      case ConnectivityMode.syncing:
        return 'Syncing content...';
    }
  }

  /// Icon data suggestion for UI (Material icon name).
  String get statusIcon {
    switch (_mode) {
      case ConnectivityMode.offline:
        return 'cloud_off';
      case ConnectivityMode.discovering:
        return 'wifi_find';
      case ConnectivityMode.online:
        return 'cloud_done';
      case ConnectivityMode.syncing:
        return 'sync';
    }
  }
}
