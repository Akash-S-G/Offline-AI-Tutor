import 'package:flutter/material.dart';

class FullscreenLabMode extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const FullscreenLabMode({
    super.key,
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      color: enabled ? Colors.black : const Color(0xFF020617),
      child: child,
    );
  }
}
