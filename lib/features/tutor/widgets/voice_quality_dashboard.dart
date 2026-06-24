import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../voice/providers/voice_connection_provider.dart';
import '../providers/conversation_provider.dart';

/// Aggregates and displays telemetry for the active voice session.
/// Shows transcript latency, audio chunk delivery counts, and reconnection counts.
class VoiceQualityDashboard extends ConsumerStatefulWidget {
  const VoiceQualityDashboard({super.key});

  @override
  ConsumerState<VoiceQualityDashboard> createState() => _VoiceQualityDashboardState();
}

class _VoiceQualityDashboardState extends ConsumerState<VoiceQualityDashboard> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Periodically refresh the dashboard to update fast-moving metrics
    // like audio chunks sent, without spamming Riverpod state updates.
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conv = ref.watch(conversationProvider);
    final voiceConn = ref.read(voiceConnectionProvider.notifier);

    final latency = conv.responseLatency.inMilliseconds;
    final chunksSent = voiceConn.socket.audioChunksSent;
    final retries = voiceConn.socket.retryAttempt;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Quality Telemetry',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                context,
                label: 'Latency',
                value: '${latency}ms',
                icon: Icons.timer_outlined,
                color: latency > 1000 ? Colors.orange : Colors.green,
              ),
              _buildMetricItem(
                context,
                label: 'Chunks',
                value: '$chunksSent',
                icon: Icons.upload_file_outlined,
                color: Colors.blue,
              ),
              _buildMetricItem(
                context,
                label: 'Retries',
                value: '$retries',
                icon: Icons.wifi_protected_setup,
                color: retries > 0 ? Colors.redAccent : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
