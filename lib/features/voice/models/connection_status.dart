/// WebSocket connection lifecycle states.
enum ConnectionStatus {
  /// No active connection.
  disconnected,

  /// Handshake in progress.
  connecting,

  /// WebSocket open and healthy.
  connected,

  /// Lost connection, attempting to restore.
  reconnecting,

  /// Unrecoverable connection failure.
  error,
}
