import 'package:flutter/material.dart';

class AnimatedScatterPlot extends StatelessWidget {
  final Widget child;
  final bool highlight;

  const AnimatedScatterPlot({
    super.key,
    required this.child,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: highlight ? 1 : 0.92,
      duration: const Duration(milliseconds: 220),
      child: child,
    );
  }
}
