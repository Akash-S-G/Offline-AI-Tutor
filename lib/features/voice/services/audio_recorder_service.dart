import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records audio from the device microphone.
///
/// Output: WAV, 16 kHz, mono — the format the backend ASR expects.
class AudioRecorderService {
  AudioRecorderService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  String? _currentFilePath;

  /// Start recording to a temporary WAV file.
  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentFilePath = '${dir.path}/voice_$timestamp.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: _currentFilePath!,
    );
  }

  /// Stop recording and return the file path.
  /// Returns `null` if nothing was being recorded.
  Future<String?> stopRecording() async {
    if (!await _recorder.isRecording()) return null;
    final path = await _recorder.stop();
    return path;
  }

  /// Cancel the current recording and delete the file.
  Future<void> cancelRecording() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentFilePath = null;
    }
  }

  /// The file path of the current/last recording (may be null).
  String? getCurrentFile() => _currentFilePath;

  /// Current amplitude (0.0–1.0 range) for waveform visualization.
  Future<double> getAmplitude() async {
    final amp = await _recorder.getAmplitude();
    // amp.current is in dBFS (negative values). Normalize to 0..1.
    final db = amp.current;
    if (db <= -60) return 0.0;
    if (db >= 0) return 1.0;
    return (db + 60) / 60;
  }

  /// Whether the recorder is currently active.
  Future<bool> isRecording() => _recorder.isRecording();

  /// Release native resources.
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
