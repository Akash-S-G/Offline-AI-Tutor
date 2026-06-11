import 'package:flutter/material.dart';

class LabButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const LabButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 1),
      duration: const Duration(milliseconds: 160),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}
