import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

class ChunkedStreamAudioSource extends StreamAudioSource {
  ChunkedStreamAudioSource({
    required Stream<List<int>> stream,
    required this.contentType,
  }) : _stream = stream;

  final Stream<List<int>> _stream;
  final String contentType;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // Return an ongoing stream of bytes without a known length
    return StreamAudioResponse(
      sourceLength: null,
      contentLength: null,
      offset: start ?? 0,
      stream: _stream,
      contentType: contentType,
    );
  }
}

/// Plays incoming audio chunks (e.g., from a WebSocket) with minimal latency.
///
/// Supports instantaneous interruption when the user speaks.
class VoiceStreamPlayer {
  VoiceStreamPlayer() : _player = AudioPlayer() {
    _initPlayer();
  }

  final AudioPlayer _player;
  StreamController<List<int>>? _audioStreamController;
  bool _isPlaying = false;

  /// Called when the audio stream has fully finished playing.
  /// Set this to transition the UI back to idle after TTS completes.
  void Function()? onComplete;

  void _initPlayer() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        onComplete?.call();
      }
    });
  }

  /// Appends a base64 encoded audio chunk to the playback stream.
  Future<void> queueAudioChunk(String base64Chunk) async {
    final bytes = base64Decode(base64Chunk);

    // If we're not currently playing, set up a new source
    if (!_isPlaying || _audioStreamController == null) {
      _audioStreamController?.close();
      _audioStreamController = StreamController<List<int>>.broadcast();

      final source = ChunkedStreamAudioSource(
        stream: _audioStreamController!.stream,
        // Assume wav/pcm for low latency
        contentType: 'audio/wav',
      );

      await _player.setAudioSource(source);
      _player.play();
      _isPlaying = true;
    }

    _audioStreamController?.add(bytes);
  }

  /// Called when the final chunk has arrived, telling the player
  /// it can transition to "completed" once the buffer is drained.
  void markComplete() {
    _audioStreamController?.close();
    _audioStreamController = null;
  }

  /// Instantly stops playback and clears the buffer.
  /// Call this when the user hits the mic to interrupt the tutor.
  Future<void> interrupt() async {
    _isPlaying = false;
    _audioStreamController?.close();
    _audioStreamController = null;
    await _player.stop();
  }

  Future<void> dispose() async {
    onComplete = null;
    _audioStreamController?.close();
    await _player.dispose();
  }
}
