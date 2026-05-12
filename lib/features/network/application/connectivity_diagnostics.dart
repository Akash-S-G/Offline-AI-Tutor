import '../data/network_state_service.dart';

class ConnectivityDiagnostics {
  const ConnectivityDiagnostics();

  String describe(NetworkStateService state) {
    return 'quality=${state.quality}, snapshot=${state.currentSnapshot}';
  }
}
