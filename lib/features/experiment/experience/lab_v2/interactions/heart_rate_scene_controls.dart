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
    final current = widget.world.variables.getValue('var_activity') ?? 0.0;
    double next = 0.0;
    if (current < 20.0) next = 20.0;
    else if (current < 50.0) next = 50.0;
    else if (current < 80.0) next = 80.0;
    else next = 100.0; // Max intensity
    widget.world.variables.setVariable('var_activity', next);
    _updateHeartRate(next);
  }

  void _decreaseActivity() {
    final current = widget.world.variables.getValue('var_activity') ?? 0.0;
    double next = 0.0;
    if (current <= 20.0) next = 0.0;
    else if (current <= 50.0) next = 20.0;
    else if (current <= 80.0) next = 50.0;
    else next = 80.0;
    widget.world.variables.setVariable('var_activity', next);
    _updateHeartRate(next);
  }

  void _updateHeartRate(double activity) {
    // Basic physiological model approximation
    double targetHR = 60.0 + (activity * 1.2);
    widget.world.variables.setVariable('var_heart_rate', targetHR);
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
