import 'package:flutter/material.dart';

class FocusModeOverlay extends StatelessWidget {
  final bool enabled;
  final VoidCallback onExit;

  const FocusModeOverlay({
    super.key,
    required this.enabled,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    return Positioned(
      top: 12,
      right: 12,
      child: FilledButton.icon(
        onPressed: onExit,
        icon: const Icon(Icons.fullscreen_exit),
        label: const Text('Exit Focus'),
      ),
    );
  }
}
