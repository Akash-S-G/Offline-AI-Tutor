import 'package:flutter/material.dart';

class RuntimeActorHighlighter extends StatelessWidget {
  final bool active;
  final Alignment alignment;

  const RuntimeActorHighlighter({
    super.key,
    required this.active,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.12),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, _) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.75),
                      width: 4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
