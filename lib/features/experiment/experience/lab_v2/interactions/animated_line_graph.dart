import 'package:flutter/material.dart';

class AnimatedLineGraph extends StatelessWidget {
  final Widget child;
  final bool highlight;

  const AnimatedLineGraph({
    super.key,
    required this.child,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: highlight ? 1.02 : 1,
      duration: const Duration(milliseconds: 220),
      child: child,
    );
  }
}
