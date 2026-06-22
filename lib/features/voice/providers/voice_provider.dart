import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/voice_state.dart';
import '../services/audio_player_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/voice_permission_service.dart';

// ─── State ──────────────────────────────────────────────────────────

class VoiceProviderState {
  const VoiceProviderState({
    this.state = VoiceState.idle,
    this.hasPermission = false,
    this.currentRecording,
    this.recordingDuration = Duration.zero,
    this.isPlaying = false,
  });

  final VoiceState state;
  final bool hasPermission;
  final String? currentRecording;
  final Duration recordingDuration;
  final bool isPlaying;

  VoiceProviderState copyWith({
    VoiceState? state,
    bool? hasPermission,
    String? currentRecording,
    Duration? recordingDuration,
    bool? isPlaying,
    bool clearRecording = false,
  }) {
    return VoiceProviderState(
      state: state ?? this.state,
      hasPermission: hasPermission ?? this.hasPermission,
      currentRecording: clearRecording ? null : (currentRecording ?? this.currentRecording),
      recordingDuration: recordingDuration ?? this.recordingDuration,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────

class VoiceNotifier extends StateNotifier<VoiceProviderState> {
  VoiceNotifier({
    VoicePermissionService? permissionService,
    AudioRecorderService? recorderService,
    AudioPlayerService? playerService,
  })  : _permissions = permissionService ?? VoicePermissionService(),
        _recorder = recorderService ?? AudioRecorderService(),
        _player = playerService ?? AudioPlayerService(),
        super(const VoiceProviderState()) {
    _listenToPlayback();
  }

  final VoicePermissionService _permissions;
  final AudioRecorderService _recorder;
  final AudioPlayerService _player;

  Timer? _durationTimer;
  StreamSubscription<bool>? _playingSub;

  // ─── Public API ─────────────────────────────────────────────────

  /// Request mic permission and start recording.
  Future<void> startRecording() async {
    final granted = await _permissions.requestMicrophonePermission();
    if (!granted) {
      state = state.copyWith(hasPermission: false, state: VoiceState.error);
      return;
    }
    state = state.copyWith(hasPermission: true);

    try {
      await _recorder.startRecording();
      state = state.copyWith(
        state: VoiceState.listening,
        recordingDuration: Duration.zero,
      );
      _startDurationTimer();
    } catch (_) {
      state = state.copyWith(state: VoiceState.error);
    }
  }

  /// Stop recording and keep the file.
  Future<void> stopRecording() async {
    _stopDurationTimer();
    try {
      final path = await _recorder.stopRecording();
      state = state.copyWith(
        state: VoiceState.idle,
        currentRecording: path,
      );
    } catch (_) {
      state = state.copyWith(state: VoiceState.error);
    }
  }

  /// Play the last recording.
  Future<void> playRecording() async {
    final path = state.currentRecording;
    if (path == null) return;
    try {
      state = state.copyWith(state: VoiceState.speaking);
      await _player.play(path);
    } catch (_) {
      state = state.copyWith(state: VoiceState.error);
    }
  }

  /// Stop playback.
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      state = state.copyWith(state: VoiceState.idle, isPlaying: false);
    } catch (_) {
      state = state.copyWith(state: VoiceState.error);
    }
  }

  /// Reset to initial state.
  Future<void> reset() async {
    _stopDurationTimer();
    try {
      if (await _recorder.isRecording()) {
        await _recorder.cancelRecording();
      }
      await _player.stop();
    } catch (_) {
      // Best-effort cleanup.
    }
    state = const VoiceProviderState();
  }

  // ─── Internal ───────────────────────────────────────────────────

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      state = state.copyWith(
        recordingDuration: state.recordingDuration + const Duration(milliseconds: 100),
      );
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _listenToPlayback() {
    _playingSub = _player.isPlayingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
      if (!playing && state.state == VoiceState.speaking) {
        state = state.copyWith(state: VoiceState.idle);
      }
    });
  }

  @override
  void dispose() {
    _stopDurationTimer();
    _playingSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}

// ─── Provider ───────────────────────────────────────────────────────

final voiceProvider =
    StateNotifierProvider<VoiceNotifier, VoiceProviderState>((ref) {
  return VoiceNotifier();
});
