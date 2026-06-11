import 'package:flutter/material.dart';

import '../../../guided_runtime/engine/guided_experiment_engine.dart';

class VisualGuidanceOverlay extends StatefulWidget {
  final GuidedExperimentEngine? guidedEngine;
  final bool hidden;

  const VisualGuidanceOverlay({
    super.key,
    required this.guidedEngine,
    this.hidden = false,
  });

  @override
  State<VisualGuidanceOverlay> createState() => _VisualGuidanceOverlayState();
}

class _VisualGuidanceOverlayState extends State<VisualGuidanceOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.guidedEngine?.state.currentTask;
    if (widget.hidden || task == null) return const SizedBox.shrink();
    return Positioned(
      right: 28,
      bottom: 132,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.south_east, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }
}
