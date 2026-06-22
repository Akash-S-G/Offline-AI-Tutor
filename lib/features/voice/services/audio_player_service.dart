import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Plays audio files using [just_audio].
///
/// Used for recording playback (debug) and tutor response audio.
class AudioPlayerService {
  AudioPlayerService() : _player = AudioPlayer();

  final AudioPlayer _player;

  /// Whether audio is currently playing.
  Stream<bool> get isPlayingStream =>
      _player.playingStream;

  /// Current playback position.
  Stream<Duration> get positionStream =>
      _player.positionStream;

  /// Total duration of the loaded audio (null until loaded).
  Duration? get duration => _player.duration;

  /// Callback for playback failures after all retries are exhausted.
  void Function(String message)? onPlaybackError;

  static const _maxRetries = 2;

  /// Play an audio file from a local path.
  /// F8: Retries up to [_maxRetries] times, then notifies via [onPlaybackError].
  Future<void> play(String path) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        await _player.setFilePath(path);
        await _player.play();
        return; // Success
      } catch (e) {
        if (attempt == _maxRetries) {
          onPlaybackError?.call('Could not play audio');
          return;
        }
        // Brief delay before retry
        await Future<void>.delayed(
          Duration(milliseconds: 200 * (attempt + 1)),
        );
      }
    }
  }

  /// Pause playback (can be resumed).
  Future<void> pause() async {
    await _player.pause();
  }

  /// Stop playback and reset position to start.
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  /// Release native resources. Call when the service is no longer needed.
  Future<void> dispose() async {
    await _player.dispose();
  }
}
