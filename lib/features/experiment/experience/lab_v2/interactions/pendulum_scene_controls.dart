import 'package:flutter/material.dart';
import '../../../runtime/runtime_world.dart';

class PendulumSceneControls extends StatefulWidget {
  final RuntimeWorld world;

  const PendulumSceneControls({super.key, required this.world});

  @override
  State<PendulumSceneControls> createState() => _PendulumSceneControlsState();
}

class _PendulumSceneControlsState extends State<PendulumSceneControls> {
  @override
  void initState() {
    super.initState();
    widget.world.eventBus.stream.listen((event) {
      if (mounted) setState(() {});
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    // Determine angle based on finger position relative to the pivot (top center)
    final pivot = Offset(size.width / 2, size.height * 0.1); // Assuming pivot is near top
    final dx = details.localPosition.dx - pivot.dx;
    final dy = details.localPosition.dy - pivot.dy;
    
    // Calculate angle in radians
    double angle = 0;
    if (dy > 0) {
      angle = -1 * (dx / dy); // simplistic projection
    }
    
    // Clamp angle to roughly -0.8 to 0.8 radians
    angle = angle.clamp(-0.8, 0.8);
    
    // Update variables directly
    widget.world.variables.setVariable('var_angle', angle);
  }

  void _onPanEnd(DragEndDetails details) {
    // Release pendulum
    widget.world.variables.setVariable('var_is_swinging', 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Drag overlay for pendulum
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) => _onPanUpdate(details, constraints.biggest),
                onPanEnd: _onPanEnd,
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ],
        );
      }
    );
  }
}
