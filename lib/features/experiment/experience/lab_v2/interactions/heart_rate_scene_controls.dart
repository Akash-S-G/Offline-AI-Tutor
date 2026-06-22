import 'package:flutter/material.dart';
import '../../../runtime/runtime_world.dart';

class HeartRateSceneControls extends StatefulWidget {
  final RuntimeWorld world;

  const HeartRateSceneControls({super.key, required this.world});

  @override
  State<HeartRateSceneControls> createState() => _HeartRateSceneControlsState();
}

class _HeartRateSceneControlsState extends State<HeartRateSceneControls> {
  void _increaseActivity() {
    final current = widget.world.variables.getValue('activity') ?? 0.0;
    widget.world.variables.setVariable('activity', (current + 20.0).clamp(0.0, 100.0));
  }

  void _decreaseActivity() {
    final current = widget.world.variables.getValue('activity') ?? 0.0;
    widget.world.variables.setVariable('activity', (current - 20.0).clamp(0.0, 100.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Treadmill tap area (Increase Activity)
            Positioned(
              left: constraints.maxWidth * 0.4,
              bottom: constraints.maxHeight * 0.1,
              width: constraints.maxWidth * 0.4,
              height: constraints.maxHeight * 0.3,
              child: GestureDetector(
                onTap: _increaseActivity,
                onDoubleTap: _decreaseActivity, // Double tap to slow down
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ],
        );
      }
    );
  }
}
