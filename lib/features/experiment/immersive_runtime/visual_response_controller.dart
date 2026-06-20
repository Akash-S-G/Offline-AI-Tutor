import 'package:flutter/material.dart';
import '../runtime/runtime_world.dart';

class VisualResponseController extends StatefulWidget {
  final RuntimeWorld world;
  final String sceneId;
  final String layerType;
  final Widget child;

  const VisualResponseController({
    super.key,
    required this.world,
    required this.sceneId,
    required this.layerType,
    required this.child,
  });

  @override
  State<VisualResponseController> createState() => _VisualResponseControllerState();
}

class _VisualResponseControllerState extends State<VisualResponseController> {
  @override
  void initState() {
    super.initState();
    widget.world.eventBus.stream.listen((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sceneId.contains('water_cycle')) {
      if (widget.layerType == 'actor') {
        final humidity = (widget.world.variables.getValue('var_humidity') as num? ?? 50.0).toDouble();
        final scale = 0.5 + (humidity / 100.0) * 1.5; // Massive scale
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: scale, end: scale),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: widget.child,
        );
      } else if (widget.layerType == 'background') {
        final temp = (widget.world.variables.getValue('var_temperature') as num? ?? 20.0).toDouble();
        final opacity = (temp / 40.0).clamp(0.2, 1.0);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: opacity, end: opacity),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Opacity(opacity: value, child: child);
          },
          child: widget.child,
        );
      }
    }
    
    if (widget.sceneId.contains('circuit')) {
      if (widget.layerType == 'effect') {
        final current = (widget.world.variables.getValue('var_current') as num? ?? 0.0).toDouble();
        final brightness = (current / 5.0).clamp(0.0, 1.0);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: brightness, end: brightness),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Opacity(opacity: value, child: Transform.scale(scale: 1.0 + value * 2.0, child: child));
          },
          child: widget.child,
        );
      } else if (widget.layerType == 'actor') {
        final switchState = (widget.world.variables.getValue('var_switch_state') as num? ?? 0.0).toDouble();
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: switchState, end: switchState),
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) {
            return Transform.rotate(angle: value * 0.5, child: child);
          },
          child: widget.child,
        );
      }
    }

    if (widget.sceneId.contains('plant_growth') && widget.layerType == 'actor') {
      final growth = (widget.world.variables.getValue('var_growth') as num? ?? 0.0).toDouble();
      final water = (widget.world.variables.getValue('var_water') as num? ?? 50.0).toDouble();
      final scale = 0.2 + (growth / 100.0) * 1.3;
      final isWilting = water < 10.0;
      
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: scale, end: scale),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) {
          Widget scaled = Transform.scale(
            scale: value,
            alignment: Alignment.bottomCenter,
            child: child,
          );
          if (isWilting) {
            scaled = Transform.rotate(
              angle: 0.3,
              alignment: Alignment.bottomCenter,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.brown, BlendMode.modulate),
                child: scaled,
              ),
            );
          }
          return scaled;
        },
        child: widget.child,
      );
    }
    
    if (widget.sceneId.contains('heart_rate') && widget.layerType == 'actor') {
      final rate = (widget.world.variables.getValue('var_heart_rate') as num? ?? 60.0).toDouble();
      final scale = 0.5 + (rate / 200.0) * 1.5;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: scale, end: scale),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: widget.child,
      );
    }
    
    if (widget.sceneId.contains('pendulum') && widget.layerType == 'actor') {
      final isSwinging = (widget.world.variables.getValue('var_is_swinging') as num? ?? 0.0).toDouble();
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: isSwinging, end: isSwinging),
        duration: const Duration(milliseconds: 150),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1.0 + (value * 0.2), // pop out when released
            child: child,
          );
        },
        child: widget.child,
      );
    }

    return widget.child;
  }
}
