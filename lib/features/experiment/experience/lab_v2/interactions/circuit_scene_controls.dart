import 'package:flutter/material.dart';
import '../../../runtime/runtime_world.dart';

class CircuitSceneControls extends StatefulWidget {
  final RuntimeWorld world;

  const CircuitSceneControls({super.key, required this.world});

  @override
  State<CircuitSceneControls> createState() => _CircuitSceneControlsState();
}

class _CircuitSceneControlsState extends State<CircuitSceneControls> {
  @override
  void initState() {
    super.initState();
    widget.world.eventBus.stream.listen((event) {
      if (mounted) setState(() {});
    });
  }

  void _toggleSwitch() {
    final current = widget.world.variables.getValue('var_switch_state') ?? 0.0;
    widget.world.variables.setVariable('var_switch_state', current == 0.0 ? 1.0 : 0.0);
  }

  void _cycleVoltage() {
    final current = widget.world.variables.getValue('var_voltage') ?? 5.0;
    double next = 5.0;
    if (current < 5.0) next = 5.0;
    else if (current < 9.0) next = 9.0;
    else if (current < 12.0) next = 12.0;
    else if (current < 24.0) next = 24.0;
    else next = 1.0;
    widget.world.variables.setVariable('var_voltage', next);
  }

  void _cycleResistance() {
    final current = widget.world.variables.getValue('var_resistance') ?? 10.0;
    double next = 10.0;
    if (current < 10.0) next = 10.0;
    else if (current < 50.0) next = 50.0;
    else if (current < 100.0) next = 100.0;
    else next = 1.0;
    widget.world.variables.setVariable('var_resistance', next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Switch Tap Area
            Positioned(
              left: constraints.maxWidth * 0.4,
              top: constraints.maxHeight * 0.4,
              width: constraints.maxWidth * 0.2,
              height: constraints.maxHeight * 0.2,
              child: GestureDetector(
                onTap: _toggleSwitch,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            
            // Battery Tap Area
            Positioned(
              left: constraints.maxWidth * 0.1,
              top: constraints.maxHeight * 0.6,
              width: constraints.maxWidth * 0.2,
              height: constraints.maxHeight * 0.2,
              child: GestureDetector(
                onTap: _cycleVoltage,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            
            // Resistor Tap Area
            Positioned(
              right: constraints.maxWidth * 0.1,
              top: constraints.maxHeight * 0.4,
              width: constraints.maxWidth * 0.2,
              height: constraints.maxHeight * 0.2,
              child: GestureDetector(
                onTap: _cycleResistance,
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ],
        );
      }
    );
  }
}
