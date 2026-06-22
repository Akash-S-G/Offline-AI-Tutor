import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../voice/models/connection_status.dart';
import '../../voice/providers/voice_connection_provider.dart';

/// Thin bar at the top of the tutor screen showing connection status.
///
/// Green = connected, amber = reconnecting, red = disconnected/error.
class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(voiceConnectionProvider);

    final (color, label) = switch (conn.status) {
      ConnectionStatus.connected    => (Colors.green, 'Connected'),
      ConnectionStatus.connecting   => (Colors.amber.shade700, 'Connecting…'),
      ConnectionStatus.reconnecting => (Colors.amber.shade700, 'Reconnecting…'),
      ConnectionStatus.disconnected => (Colors.red, 'Disconnected'),
      ConnectionStatus.error        => (Colors.red, conn.error ?? 'Error'),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      color: color.withAlpha(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
