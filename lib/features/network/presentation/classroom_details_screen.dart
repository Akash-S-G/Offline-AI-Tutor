import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/backend_discovery_provider.dart';
import '../services/backend_discovery_service.dart';

class ClassroomDetailsScreen extends ConsumerWidget {
  const ClassroomDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(classroomConnectionProvider);
    final classroom = connection.currentClassroom;

    return Scaffold(
      appBar: AppBar(title: const Text('Classroom Connection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusHeader(connection: connection),
          const SizedBox(height: 20),
          if (classroom != null) ...[
            _DetailRow(label: 'Name', value: classroom.name),
            _DetailRow(label: 'Gateway URL', value: classroom.gatewayUrl),
            _DetailRow(label: 'Node ID', value: classroom.nodeId),
            _DetailRow(
              label: 'Latency',
              value: classroom.latencyMs == null
                  ? 'Not measured'
                  : '${classroom.latencyMs} ms',
            ),
            _DetailRow(
              label: 'Last connected',
              value:
                  classroom.lastConnectedAt?.toLocal().toString() ??
                  'Not available',
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No classroom is connected. Retry discovery or enter the '
                'classroom gateway address manually from the P2P screen.',
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: connection.isDiscovering
                ? null
                : () => connection.discover(force: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry Discovery'),
          ),
          if (classroom != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => connection.disconnect(forget: true),
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Forget Classroom'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.connection});

  final BackendDiscoveryService connection;

  @override
  Widget build(BuildContext context) {
    final connected = connection.isConnected;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: connected
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEE2E2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: connected
                ? const Color(0xFF166534)
                : const Color(0xFF991B1B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                connected ? 'Connected' : 'Not Connected',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                connection.state.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
