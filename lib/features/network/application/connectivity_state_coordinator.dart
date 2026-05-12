import '../data/network_state_service.dart';

class ConnectivityStateSnapshot {
  const ConnectivityStateSnapshot({
    required this.backendConnected,
    required this.pihubConnected,
    required this.syncing,
    required this.offlineMode,
    required this.routingMode,
  });

  final bool backendConnected;
  final bool pihubConnected;
  final bool syncing;
  final bool offlineMode;
  final String routingMode;
}

class ConnectivityStateCoordinator {
  ConnectivityStateCoordinator();

  ConnectivityStateSnapshot build({
    required NetworkStateService network,
    required bool pihubConnected,
    required bool syncing,
    required String routingMode,
  }) {
    return ConnectivityStateSnapshot(
      backendConnected: network.currentSnapshot?.hasBackend ?? false,
      pihubConnected: pihubConnected,
      syncing: syncing,
      offlineMode: network.quality.name == 'offline',
      routingMode: routingMode,
    );
  }
}
