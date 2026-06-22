import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/connection_status.dart';
import '../models/voice_event.dart';
import '../../session/models/session_info.dart';

/// Manages the WebSocket connection to the laptop voice server.
///
/// Connects to `ws://<host>:<port>/voice`, sends audio chunks,
/// and exposes a stream of [VoiceEvent]s for the UI layer.
class VoiceSocketService {
  SessionInfo? activeSession;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final _eventController = StreamController<VoiceEvent>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;

  // F8: Exponential backoff retry
  String? _lastUrl;
  int _retryAttempt = 0;
  Timer? _retryTimer;
  static const _maxRetryDelaySec = 16;
  static const _maxRetries = 10;

  // ─── Public API ─────────────────────────────────────────────────

  /// Stream of parsed events from the server.
  Stream<VoiceEvent> get eventStream => _eventController.stream;

  /// Stream of connection lifecycle changes.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Current connection status (synchronous read).
  ConnectionStatus get status => _status;

  /// Open a WebSocket to the voice endpoint.
  Future<void> connect(String url) async {
    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      return;
    }

    _lastUrl = url;
    _setStatus(ConnectionStatus.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _setStatus(ConnectionStatus.connected);
      _retryAttempt = 0; // Reset on successful connect

      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (_) {
      _setStatus(ConnectionStatus.error);
      _eventController.add(const VoiceEvent(
        type: VoiceEventType.error,
        payload: {'message': 'Tutor unavailable'},
      ));
      _scheduleRetry();
    }
  }

  /// Gracefully close the connection.
  void disconnect() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryAttempt = 0;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  /// Drop the current connection and re-establish.
  Future<void> reconnect(String url) async {
    _setStatus(ConnectionStatus.reconnecting);
    disconnect();
    await connect(url);
  }

  /// Send a raw audio chunk (bytes) to the server.
  void sendAudioChunk(Uint8List bytes) {
    if (_status != ConnectionStatus.connected) return;
    final event = VoiceEvent(
      type: VoiceEventType.audioData,
      payload: {'audio': base64Encode(bytes)},
      sessionId: activeSession?.sessionId,
      deviceId: activeSession?.deviceId,
      studentId: activeSession?.studentId,
    );
    _channel?.sink.add(jsonEncode(event.toJson()));
  }

  /// Signal to the server that audio recording is complete.
  void sendAudioComplete({Map<String, dynamic>? context}) {
    if (_status != ConnectionStatus.connected) return;
    final event = VoiceEvent(
      type: VoiceEventType.audioComplete,
      payload: context != null ? {'context': context} : const {},
      sessionId: activeSession?.sessionId,
      deviceId: activeSession?.deviceId,
      studentId: activeSession?.studentId,
    );
    _channel?.sink.add(jsonEncode(event.toJson()));
  }

  /// Send an arbitrary JSON event.
  void sendEvent(VoiceEvent event) {
    if (_status != ConnectionStatus.connected) return;
    final evt = VoiceEvent(
      type: event.type,
      payload: event.payload,
      sessionId: event.sessionId ?? activeSession?.sessionId,
      deviceId: event.deviceId ?? activeSession?.deviceId,
      studentId: event.studentId ?? activeSession?.studentId,
    );
    _channel?.sink.add(jsonEncode(evt.toJson()));
  }

  /// Release all resources.
  void dispose() {
    _retryTimer?.cancel();
    disconnect();
    _eventController.close();
    _statusController.close();
  }

  // ─── F8: Retry with backoff ─────────────────────────────────────

  void _scheduleRetry() {
    if (_lastUrl == null || _retryAttempt >= _maxRetries) return;
    _retryAttempt++;
    final delaySec = (1 << (_retryAttempt - 1)).clamp(1, _maxRetryDelaySec);
    _setStatus(ConnectionStatus.reconnecting);
    _eventController.add(VoiceEvent(
      type: VoiceEventType.error,
      payload: {'message': 'Reconnecting in ${delaySec}s…'},
    ));
    _retryTimer = Timer(Duration(seconds: delaySec), () {
      if (_status != ConnectionStatus.connected) {
        connect(_lastUrl!);
      }
    });
  }

  // ─── Internal ───────────────────────────────────────────────────

  void _setStatus(ConnectionStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      _eventController.add(VoiceEvent.fromJson(json));
    } catch (e) {
      _eventController.add(VoiceEvent(
        type: VoiceEventType.error,
        payload: {'message': 'Failed to parse server event: $e'},
      ));
    }
  }

  void _onError(Object error) {
    _setStatus(ConnectionStatus.error);
    // F8: Never surface raw exceptions to UI
    _eventController.add(const VoiceEvent(
      type: VoiceEventType.error,
      payload: {'message': 'Tutor unavailable'},
    ));
    _scheduleRetry();
  }

  void _onDone() {
    if (_status != ConnectionStatus.disconnected) {
      _setStatus(ConnectionStatus.disconnected);
      _scheduleRetry();
    }
  }
}
