import 'package:flutter/material.dart';

class LaboratoryDock extends StatelessWidget {
  final VoidCallback onRun;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback onReset;
  final VoidCallback? onObserve;
  final VoidCallback? onMeasure;
  final VoidCallback? onOpenInvestigation;
  final bool isRunning;
  final bool isPaused;
  final bool isPreparing;

  const LaboratoryDock({
    super.key,
    required this.onRun,
    required this.onReset,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onObserve,
    this.onMeasure,
    this.onOpenInvestigation,
    this.isRunning = false,
    this.isPaused = false,
    this.isPreparing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF20F172A),
          border: const Border(top: BorderSide(color: Color(0xFF334155))),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              _DockAction(
                icon: _runIcon,
                label: _runLabel,
                color: _runColor,
                onPressed: _runAction,
              ),
              if (isRunning || isPaused)
                _DockAction(
                  icon: Icons.stop_rounded,
                  label: 'Stop',
                  onPressed: onStop,
                ),
              _DockAction(
                icon: Icons.restart_alt_rounded,
                label: 'Reset',
                onPressed: onReset,
              ),
              const SizedBox(width: 10),
              const VerticalDivider(color: Color(0xFF334155), width: 18),
              _DockAction(
                icon: Icons.visibility_rounded,
                label: 'Observe',
                onPressed: onObserve,
              ),
              _DockAction(
                icon: Icons.straighten_rounded,
                label: 'Measure',
                onPressed: onMeasure,
              ),
              const Spacer(),
              _DockAction(
                icon: Icons.assignment_outlined,
                label: 'Investigation',
                onPressed: onOpenInvestigation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _runIcon {
    if (isPreparing) return Icons.hourglass_top_rounded;
    if (isRunning) return Icons.pause_rounded;
    if (isPaused) return Icons.play_arrow_rounded;
    return Icons.play_arrow_rounded;
  }

  String get _runLabel {
    if (isPreparing) return 'Ready';
    if (isRunning) return 'Pause';
    if (isPaused) return 'Resume';
    return 'Run';
  }

  Color get _runColor {
    if (isRunning) return const Color(0xFFF59E0B);
    if (isPaused) return const Color(0xFF3B82F6);
    return const Color(0xFF10B981);
  }

  VoidCallback? get _runAction {
    if (isPreparing) return null;
    if (isRunning) return onPause;
    if (isPaused) return onResume;
    return onRun;
  }
}

class _DockAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const _DockAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: 48,
          height: 44,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onPressed,
            icon: Icon(icon, color: foreground),
          ),
        ),
      ),
    );
  }
}
