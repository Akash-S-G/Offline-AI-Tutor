import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_status.dart';
import '../models/voice_event.dart';
import '../services/voice_connectivity_service.dart';
import '../services/voice_socket_service.dart';
import '../../session/providers/session_provider.dart';
import '../../network/providers/backend_discovery_provider.dart';

// ─── State ──────────────────────────────────────────────────────────

class VoiceConnectionState {
  const VoiceConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.latency = 0.0,
    this.error,
  });

  final ConnectionStatus status;

  /// Last measured round-trip latency in milliseconds.
  final double latency;

  /// Human-readable error (null when healthy).
  final String? error;

  VoiceConnectionState copyWith({
    ConnectionStatus? status,
    double? latency,
    String? error,
    bool clearError = false,
  }) {
    return VoiceConnectionState(
      status: status ?? this.status,
      latency: latency ?? this.latency,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────

class VoiceConnectionNotifier extends StateNotifier<VoiceConnectionState> {
  VoiceConnectionNotifier({
    VoiceSocketService? socketService,
    VoiceConnectivityService? connectivityService,
  }) : _socket = socketService ?? VoiceSocketService(),
       _connectivity = connectivityService ?? VoiceConnectivityService(),
       super(const VoiceConnectionState()) {
    _listenToStatus();
    _listenToEvents();

    // F8: Reconnect when network recovers
    _connectivity.onReconnect = () {
      if (_lastUrl != null && state.status != ConnectionStatus.connected) {
        connect(_lastUrl!);
      }
    };
  }

  final VoiceSocketService _socket;
  final VoiceConnectivityService _connectivity;
  StreamSubscription<ConnectionStatus>? _statusSub;
  StreamSubscription<VoiceEvent>? _eventSub;
  String? _lastUrl;

  /// The underlying socket service (needed by conversation layer).
  VoiceSocketService get socket => _socket;

  // ─── Public API ─────────────────────────────────────────────────

  /// Connect to the voice WebSocket endpoint.
  Future<void> connect(String url) async {
    _lastUrl = url;
    state = state.copyWith(clearError: true);
    await _socket.connect(url);
  }

  /// Gracefully disconnect.
  void disconnect() {
    _socket.disconnect();
  }

  /// Drop and re-establish connection.
  Future<void> reconnect(String url) async {
    state = state.copyWith(clearError: true);
    await _socket.reconnect(url);
  }

  // ─── Internal ───────────────────────────────────────────────────

  void _listenToStatus() {
    _statusSub = _socket.statusStream.listen((s) {
      state = state.copyWith(status: s);
    });
  }

  void _listenToEvents() {
    _eventSub = _socket.eventStream.listen((event) {
      if (event.type == VoiceEventType.error) {
        state = state.copyWith(error: event.payload['message'] as String?);
      }
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _eventSub?.cancel();
    _socket.dispose();
    super.dispose();
  }
}

// ─── Provider ───────────────────────────────────────────────────────
//
// IMPORTANT: We use ref.listen (not ref.watch) for both sessionProvider and
// backendDiscoveryProvider so that the notifier is created ONCE and stays
// stable for the lifetime of the app.
//
// The previous pattern used ref.watch inside the factory, which caused the
// entire StateNotifierProvider to rebuild (creating a new notifier + a new
// VoiceSocketService) every time the backend was discovered. This meant that
// VoiceNotifier's socket event subscription — wired once in its constructor —
// was pointing to the old, dead socket and never received events.

final voiceConnectionProvider =
    StateNotifierProvider<VoiceConnectionNotifier, VoiceConnectionState>((ref) {
  final notifier = VoiceConnectionNotifier();

  // Keep session metadata up to date without recreating the notifier.
  ref.listen<dynamic>(sessionProvider, (_, session) {
    notifier.socket.activeSession = session;
  }, fireImmediately: true);

  // Connect / reconnect whenever the discovered backend endpoint changes.
  ref.listen<String?>(
    backendDiscoveryProvider.select((s) => s.activeEndpoint),
    (_, endpoint) {
      if (endpoint != null && endpoint.isNotEmpty) {
        // Convert http(s) → ws(s) and append the voice WebSocket path.
        final wsUrl = endpoint
            .replaceFirst('https://', 'wss://')
            .replaceFirst('http://', 'ws://');
        notifier.connect('$wsUrl/api/v1/voice/stream');
      }
    },
    fireImmediately: true,
  );

  return notifier;
});
