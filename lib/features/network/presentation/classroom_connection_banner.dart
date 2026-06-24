import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/backend_discovery_provider.dart';
import '../services/backend_discovery_service.dart';
import 'classroom_details_screen.dart';

class ClassroomConnectionBanner extends ConsumerWidget {
  const ClassroomConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(classroomConnectionProvider);
    final presentation = _presentation(connection);

    return SafeArea(
      bottom: false,
      child: Material(
        color: presentation.background,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ClassroomDetailsScreen(),
              ),
            );
          },
          child: SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    presentation.icon,
                    size: 16,
                    color: presentation.foreground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      presentation.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: presentation.foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (connection.isDiscovering)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: presentation.foreground,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: presentation.foreground,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _BannerPresentation _presentation(BackendDiscoveryService connection) {
    final classroom = connection.currentClassroom;
    return switch (connection.state) {
      ClassroomConnectionState.connected => _BannerPresentation(
        label: 'Connected to ${classroom?.name ?? 'classroom'}',
        icon: Icons.wifi_rounded,
        background: const Color(0xFFDCFCE7),
        foreground: const Color(0xFF166534),
      ),
      ClassroomConnectionState.discovering => const _BannerPresentation(
        label: 'Searching for classrooms...',
        icon: Icons.wifi_find_rounded,
        background: Color(0xFFFEF3C7),
        foreground: Color(0xFF92400E),
      ),
      ClassroomConnectionState.connecting => const _BannerPresentation(
        label: 'Connecting to classroom...',
        icon: Icons.sync_rounded,
        background: Color(0xFFFEF3C7),
        foreground: Color(0xFF92400E),
      ),
      ClassroomConnectionState.reconnecting => const _BannerPresentation(
        label: 'Classroom connection lost. Reconnecting...',
        icon: Icons.sync_problem_rounded,
        background: Color(0xFFFEF3C7),
        foreground: Color(0xFF92400E),
      ),
      ClassroomConnectionState.disconnected => const _BannerPresentation(
        label: 'Not connected to a classroom',
        icon: Icons.wifi_off_rounded,
        background: Color(0xFFFEE2E2),
        foreground: Color(0xFF991B1B),
      ),
    };
  }
}

class _BannerPresentation {
  const _BannerPresentation({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
}
