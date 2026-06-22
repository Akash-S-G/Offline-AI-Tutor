import 'package:flutter/material.dart';
import '../../../runtime/runtime_world.dart';

class WaterCycleSceneControls extends StatefulWidget {
  final RuntimeWorld world;

  const WaterCycleSceneControls({super.key, required this.world});

  @override
  State<WaterCycleSceneControls> createState() => _WaterCycleSceneControlsState();
}

class _WaterCycleSceneControlsState extends State<WaterCycleSceneControls> {
  void _changeTemperature(double delta) {
    final current = widget.world.variables.getValue('temperature') ?? 20.0;
    double next = (current + delta).clamp(0.0, 100.0);
    widget.world.variables.setVariable('temperature', next);
  }

  void _changeHumidity(double delta) {
    final current = widget.world.variables.getValue('humidity') ?? 20.0;
    double next = (current + delta).clamp(0.0, 100.0);
    widget.world.variables.setVariable('humidity', next);
  }

  void _resetSimulation() {
    widget.world.variables.setVariable('temperature', 20.0);
    widget.world.variables.setVariable('humidity', 20.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Sun area - Temperature
            Positioned(
              left: constraints.maxWidth * 0.7,
              top: constraints.maxHeight * 0.1,
              width: constraints.maxWidth * 0.2,
              height: constraints.maxHeight * 0.2,
              child: GestureDetector(
                onTap: () => _changeTemperature(10.0),
                onLongPress: () => _changeTemperature(-10.0),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            
            // Cloud area - Humidity
            Positioned(
              left: constraints.maxWidth * 0.2,
              top: constraints.maxHeight * 0.1,
              width: constraints.maxWidth * 0.3,
              height: constraints.maxHeight * 0.2,
              child: GestureDetector(
                onTap: () => _changeHumidity(10.0),
                onLongPress: () => _changeHumidity(-10.0),
                behavior: HitTestBehavior.translucent,
              ),
            ),

            // Lake area - Reset
            Positioned(
              left: constraints.maxWidth * 0.1,
              bottom: constraints.maxHeight * 0.1,
              width: constraints.maxWidth * 0.8,
              height: constraints.maxHeight * 0.3,
              child: GestureDetector(
                onTap: _resetSimulation,
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ],
        );
      }
    );
  }
}
