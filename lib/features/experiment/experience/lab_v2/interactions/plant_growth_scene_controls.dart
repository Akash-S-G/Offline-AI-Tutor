import 'package:flutter/material.dart';
import '../../../runtime/runtime_world.dart';

class PlantGrowthSceneControls extends StatefulWidget {
  final RuntimeWorld world;

  const PlantGrowthSceneControls({super.key, required this.world});

  @override
  State<PlantGrowthSceneControls> createState() => _PlantGrowthSceneControlsState();
}

class _PlantGrowthSceneControlsState extends State<PlantGrowthSceneControls> {
  void _waterPlant() {
    final current = widget.world.variables.getValue('var_water') ?? 0.0;
    widget.world.variables.setVariable('var_water', (current + 20.0).clamp(0.0, 100.0));
    _triggerGrowth();
  }

  void _cycleSunlight() {
    final current = widget.world.variables.getValue('var_sunlight') ?? 50.0;
    double next = 50.0;
    if (current < 50.0) next = 50.0;
    else if (current < 100.0) next = 100.0;
    else next = 25.0;
    widget.world.variables.setVariable('var_sunlight', next);
    _triggerGrowth();
  }

  void _triggerGrowth() {
    final water = widget.world.variables.getValue('var_water') ?? 0.0;
    final sun = widget.world.variables.getValue('var_sunlight') ?? 0.0;
    final growth = widget.world.variables.getValue('var_growth') ?? 0.0;
    
    if (water > 20 && sun > 20) {
      widget.world.variables.setVariable('var_growth', (growth + 10.0).clamp(0.0, 100.0));
      widget.world.variables.setVariable('var_water', (water - 10.0).clamp(0.0, 100.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Watering can tap area
            Positioned(
              left: constraints.maxWidth * 0.1,
              top: constraints.maxHeight * 0.4,
              width: constraints.maxWidth * 0.2,
              height: constraints.maxHeight * 0.3,
              child: GestureDetector(
                onTap: _waterPlant,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            
            // Sun tap area
            Positioned(
              right: constraints.maxWidth * 0.1,
              top: constraints.maxHeight * 0.1,
              width: constraints.maxWidth * 0.2,
              height: constraints.maxHeight * 0.2,
              child: GestureDetector(
                onTap: _cycleSunlight,
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ],
        );
      }
    );
  }
}
