import 'dart:async';

import 'package:flutter/material.dart';

import '../services/audio_recorder_service.dart';

/// Simple amplitude bar visualization during recording.
///
/// Polls [AudioRecorderService.getAmplitude] and draws vertical bars.
class RecordingWaveform extends StatefulWidget {
  const RecordingWaveform({
    super.key,
    required this.recorder,
    this.isRecording = false,
    this.barCount = 20,
    this.height = 48,
  });

  final AudioRecorderService recorder;
  final bool isRecording;
  final int barCount;
  final double height;

  @override
  State<RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<RecordingWaveform> {
  late List<double> _amplitudes;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _amplitudes = List.filled(widget.barCount, 0.0);
  }

  @override
  void didUpdateWidget(RecordingWaveform old) {
    super.didUpdateWidget(old);
    if (widget.isRecording && !old.isRecording) {
      _startPolling();
    } else if (!widget.isRecording && old.isRecording) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      if (!mounted) return;
      final amp = await widget.recorder.getAmplitude();
      setState(() {
        _amplitudes.removeAt(0);
        _amplitudes.add(amp);
      });
    });
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() {
        _amplitudes = List.filled(widget.barCount, 0.0);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _amplitudes.map((amp) {
          final barHeight = (amp * widget.height).clamp(2.0, widget.height);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            width: 4,
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: color.withAlpha((150 + (amp * 105)).toInt()),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }
}
