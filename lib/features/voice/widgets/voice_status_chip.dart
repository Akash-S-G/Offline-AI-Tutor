import 'package:flutter/material.dart';

import '../models/voice_state.dart';

/// Small chip showing the current [VoiceState] as human-readable text.
///
/// Color-coded: idle=grey, listening=blue, processing=amber,
/// speaking=green, error=red.
class VoiceStatusChip extends StatelessWidget {
  const VoiceStatusChip({super.key, required this.state});

  final VoiceState state;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _config(state);
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withAlpha(25),
      side: BorderSide(color: color.withAlpha(60)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  (String, Color, IconData) _config(VoiceState s) {
    return switch (s) {
      VoiceState.idle       => ('Ready', Colors.grey, Icons.mic_none_rounded),
      VoiceState.listening  => ('Listening…', Colors.blue, Icons.hearing_rounded),
      VoiceState.processing => ('Processing…', Colors.amber.shade700, Icons.sync_rounded),
      VoiceState.speaking   => ('Playing', Colors.green, Icons.volume_up_rounded),
      VoiceState.error      => ('Error', Colors.red, Icons.error_outline_rounded),
    };
  }
}
