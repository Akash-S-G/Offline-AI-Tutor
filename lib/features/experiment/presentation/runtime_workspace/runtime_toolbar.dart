import 'package:flutter/material.dart';

class RuntimeToolbar extends StatelessWidget {
  final String experimentName;
  final String status;
  final Duration elapsed;
  final int warningCount;
  final bool developerMode;
  final VoidCallback onToggleDebug;
  final VoidCallback? onExit;

  const RuntimeToolbar({
    super.key,
    required this.experimentName,
    required this.status,
    required this.elapsed,
    required this.warningCount,
    required this.developerMode,
    required this.onToggleDebug,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          if (onExit != null) ...[
            IconButton(
              onPressed: onExit,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Back',
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              experimentName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _toolbarChip(status, Icons.circle, _statusColor(status)),
          const SizedBox(width: 8),
          _toolbarChip(
            _formatDuration(elapsed),
            Icons.timer_outlined,
            Colors.blue,
          ),
          const SizedBox(width: 8),
          _toolbarChip('$warningCount', Icons.warning_amber, Colors.orange),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onToggleDebug,
            icon: Icon(
              developerMode ? Icons.school_outlined : Icons.bug_report_outlined,
              size: 18,
            ),
            label: Text(developerMode ? 'Student' : 'Debug'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF64748B)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return Colors.green;
      case 'PAUSED':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.lightBlue;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
