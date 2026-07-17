import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/connection_status.dart';
import '../models/voice_event.dart';
import '../../session/models/session_info.dart';
import '../../language/services/language_interceptor.dart';

/// Manages the WebSocket connection to the laptop voice server.
///
/// Connects to `ws://<host>:<port>/voice`, sends audio chunks,
/// and exposes a stream of [VoiceEvent]s for the UI layer.
class VoiceSocketService {
  SessionInfo? activeSession;
  LanguageInterceptor? interceptor;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final _eventController = StreamController<VoiceEvent>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  bool _isDisposed = false;

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

  /// Number of times the socket has reconnected
  int get retryAttempt => _retryAttempt;

  /// Number of audio chunks sent
  int audioChunksSent = 0;

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
      if (!_isDisposed) {
        _setStatus(ConnectionStatus.error);
        if (!_eventController.isClosed) {
          _eventController.add(const VoiceEvent(
            type: VoiceEventType.error,
            payload: {'message': 'Tutor unavailable'},
          ));
        }
        _scheduleRetry();
      }
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

  /// Send a session_start message to initialize language.
  void sendSessionStart(String language) {
    if (_status != ConnectionStatus.connected) return;
    // If no real session is available yet, generate a fallback ID.
    // The backend rejects audio_chunk when session_id is "unknown", so we
    // must always supply a non-empty, non-null identifier.
    final sid = (activeSession?.sessionId?.isNotEmpty == true)
        ? activeSession!.sessionId
        : 'anon_${DateTime.now().millisecondsSinceEpoch}';
    VoiceEvent event = VoiceEvent(
      type: VoiceEventType.sessionStart,
      language: language,
      sessionId: sid,
      deviceId: activeSession?.deviceId,
      studentId: activeSession?.studentId,
    );
    if (interceptor != null) {
      event = interceptor!.interceptOutgoing(event);
    }
    _channel?.sink.add(jsonEncode(event.toJson()));
  }

  /// Send a raw audio chunk (bytes) to the server.
  void sendAudioChunk(Uint8List bytes, int sequence) {
    if (_status != ConnectionStatus.connected) return;
    audioChunksSent++;
    VoiceEvent event = VoiceEvent(
      type: VoiceEventType.audioChunk,
      data: base64Encode(bytes),
      sequence: sequence,
      sessionId: activeSession?.sessionId,
      deviceId: activeSession?.deviceId,
      studentId: activeSession?.studentId,
    );
    if (interceptor != null) {
      event = interceptor!.interceptOutgoing(event);
    }
    _channel?.sink.add(jsonEncode(event.toJson()));
  }

  /// Signal to the server that audio recording is complete.
  void sendAudioComplete(String language, {Map<String, dynamic>? context}) {
    if (_status != ConnectionStatus.connected) return;
    VoiceEvent event = VoiceEvent(
      type: VoiceEventType.audioComplete,
      language: language,
      payload: context != null ? {'simulation_context': context} : const {},
      sessionId: activeSession?.sessionId,
      deviceId: activeSession?.deviceId,
      studentId: activeSession?.studentId,
    );
    if (interceptor != null) {
      event = interceptor!.interceptOutgoing(event);
    }
    _channel?.sink.add(jsonEncode(event.toJson()));
  }

  /// Send an arbitrary JSON event.
  void sendEvent(VoiceEvent event) {
    if (_status != ConnectionStatus.connected) return;
    VoiceEvent evt = VoiceEvent(
      type: event.type,
      payload: event.payload,
      sessionId: event.sessionId ?? activeSession?.sessionId,
      deviceId: event.deviceId ?? activeSession?.deviceId,
      studentId: event.studentId ?? activeSession?.studentId,
      language: event.language,
    );
    if (interceptor != null) {
      evt = interceptor!.interceptOutgoing(evt);
    }
    _channel?.sink.add(jsonEncode(evt.toJson()));
  }

  /// Release all resources.
  void dispose() {
    _isDisposed = true;
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
    if (!_isDisposed && !_eventController.isClosed) {
      _eventController.add(VoiceEvent(
        type: VoiceEventType.error,
        payload: {'message': 'Reconnecting in ${delaySec}s…'},
      ));
    }
    _retryTimer = Timer(Duration(seconds: delaySec), () {
      if (_status != ConnectionStatus.connected) {
        connect(_lastUrl!);
      }
    });
  }

  // ─── Internal ───────────────────────────────────────────────────

  void _setStatus(ConnectionStatus s) {
    _status = s;
    if (!_isDisposed && !_statusController.isClosed) {
      _statusController.add(s);
    }
  }

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = VoiceEvent.fromJson(json);
      if (interceptor == null || interceptor!.validateIncoming(event)) {
        if (!_isDisposed && !_eventController.isClosed) {
          _eventController.add(event);
        }
      }
    } catch (e) {
      if (!_isDisposed && !_eventController.isClosed) {
        _eventController.add(VoiceEvent(
          type: VoiceEventType.error,
          payload: {'message': 'Failed to parse server event: $e'},
        ));
      }
    }
  }

  void _onError(Object error) {
    _setStatus(ConnectionStatus.error);
    // F8: Never surface raw exceptions to UI
    if (!_isDisposed && !_eventController.isClosed) {
      _eventController.add(const VoiceEvent(
        type: VoiceEventType.error,
        payload: {'message': 'Tutor unavailable'},
      ));
    }
    _scheduleRetry();
  }

  void _onDone() {
    if (_status != ConnectionStatus.disconnected) {
      _setStatus(ConnectionStatus.disconnected);
      _scheduleRetry();
    }
  }
}
