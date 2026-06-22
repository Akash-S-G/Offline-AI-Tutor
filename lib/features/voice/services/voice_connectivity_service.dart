import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Network connectivity monitor for the voice feature.
///
/// States: online, offline, reconnecting.
/// Triggers reconnect callbacks on network recovery.
class VoiceConnectivityService {
  VoiceConnectivityService() {
    _subscription = Connectivity().onConnectivityChanged.listen(_onChange);
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final _stateController = StreamController<NetworkState>.broadcast();
  NetworkState _state = NetworkState.online;

  /// Stream of connectivity state changes.
  Stream<NetworkState> get stateStream => _stateController.stream;

  /// Current connectivity state (synchronous read).
  NetworkState get state => _state;

  /// Callback invoked when network comes back online.
  void Function()? onReconnect;

  void _onChange(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    final newState = hasConnection ? NetworkState.online : NetworkState.offline;

    if (newState != _state) {
      final wasOffline = _state == NetworkState.offline;
      _state = newState;
      _stateController.add(newState);

      // Trigger reconnect when coming back online
      if (wasOffline && newState == NetworkState.online) {
        _state = NetworkState.reconnecting;
        _stateController.add(NetworkState.reconnecting);
        onReconnect?.call();
        // After reconnect attempt, settle to online
        _state = NetworkState.online;
        _stateController.add(NetworkState.online);
      }
    }
  }

  /// Release all resources.
  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }
}

enum NetworkState {
  online,
  offline,
  reconnecting,
}
