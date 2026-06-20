import 'package:flutter/material.dart';
import '../../../runtime/runtime_world.dart';

class WaterCycleSceneControls extends StatefulWidget {
  final RuntimeWorld world;

  const WaterCycleSceneControls({super.key, required this.world});

  @override
  State<WaterCycleSceneControls> createState() => _WaterCycleSceneControlsState();
}

class _WaterCycleSceneControlsState extends State<WaterCycleSceneControls> {
  void _cycleTemperature() {
    final current = widget.world.variables.getValue('var_temperature') ?? 20.0;
    double next = 20.0;
    if (current < 20.0) next = 20.0;
    else if (current < 30.0) next = 30.0;
    else if (current < 40.0) next = 40.0;
    else next = 10.0;
    widget.world.variables.setVariable('var_temperature', next);
  }

  void _cycleHumidity() {
    final current = widget.world.variables.getValue('var_humidity') ?? 50.0;
    double next = 50.0;
    if (current < 50.0) next = 50.0;
    else if (current < 75.0) next = 75.0;
    else if (current < 100.0) next = 100.0;
    else next = 25.0;
    widget.world.variables.setVariable('var_humidity', next);
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
                onTap: _cycleTemperature,
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
                onTap: _cycleHumidity,
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ],
        );
      }
    );
  }
}
