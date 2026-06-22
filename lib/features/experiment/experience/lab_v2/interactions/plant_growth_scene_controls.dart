import 'package:flutter/material.dart';
import '../../../runtime/runtime_world.dart';

class PlantGrowthSceneControls extends StatefulWidget {
  final RuntimeWorld world;

  const PlantGrowthSceneControls({super.key, required this.world});

  @override
  State<PlantGrowthSceneControls> createState() => _PlantGrowthSceneControlsState();
}

class _PlantGrowthSceneControlsState extends State<PlantGrowthSceneControls> {
  void _changeVariable(String variable, double delta) {
    final current = widget.world.variables.getValue(variable) ?? 0.0;
    double next = (current + delta).clamp(0.0, 100.0);
    widget.world.variables.setVariable(variable, next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Watering can area - Water
            Positioned(
              left: constraints.maxWidth * 0.1,
              top: constraints.maxHeight * 0.4,
              width: constraints.maxWidth * 0.2,
              height: constraints.maxHeight * 0.3,
              child: GestureDetector(
                onTap: () => _changeVariable('water', 10.0),
                onLongPress: () => _changeVariable('water', -10.0),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            
            // Sun area - Sunlight
            Positioned(
              right: constraints.maxWidth * 0.1,
              top: constraints.maxHeight * 0.1,
              width: constraints.maxWidth * 0.2,
              height: constraints.maxHeight * 0.2,
              child: GestureDetector(
                onTap: () => _changeVariable('sunlight', 10.0),
                onLongPress: () => _changeVariable('sunlight', -10.0),
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ],
        );
      }
    );
  }
}
