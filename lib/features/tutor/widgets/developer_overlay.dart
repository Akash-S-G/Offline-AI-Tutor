import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/conversation_provider.dart';

/// Togglable debug overlay showing raw conversation internals.
///
/// Only visible in developer mode. Shows detected language,
/// translated English, raw transcript, latency.
class DeveloperOverlay extends ConsumerWidget {
  const DeveloperOverlay({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visible) return const SizedBox.shrink();

    final conv = ref.watch(conversationProvider);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.greenAccent,
          fontFamily: 'monospace',
          fontSize: 11,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('— Developer Overlay —',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('State: ${conv.state.name}'),
            Text('Partial: ${conv.partialTranscript}'),
            Text('Final: ${conv.finalTranscript}'),
            Text('Latency: ${conv.responseLatency.inMilliseconds}ms'),
            Text('Messages: ${conv.messages.length}'),
          ],
        ),
      ),
    );
  }
}
