import 'dart:math' as math;
import 'package:flutter/material.dart';

class IdleAnimationController extends StatefulWidget {
  final String sceneId;
  final String layerType;
  final Widget child;

  const IdleAnimationController({
    super.key,
    required this.sceneId,
    required this.layerType,
    required this.child,
  });

  @override
  State<IdleAnimationController> createState() => _IdleAnimationControllerState();
}

class _IdleAnimationControllerState extends State<IdleAnimationController>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sceneId.contains('water_cycle') && widget.layerType == 'background') {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_controller.value * 100 - 50, 0),
            child: child,
          );
        },
        child: widget.child,
      );
    }
    
    if (widget.sceneId.contains('pendulum') && widget.layerType == 'background') {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_controller.value * 0.05),
            child: child,
          );
        },
        child: widget.child,
      );
    }
    
    if (widget.sceneId.contains('plant_growth') && widget.layerType == 'actor') {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: (_controller.value * 0.2) - 0.1,
            child: child,
          );
        },
        child: widget.child,
      );
    }
    
    if (widget.sceneId.contains('heart_rate') && widget.layerType == 'actor') {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_controller.value * 0.15),
            child: child,
          );
        },
        child: widget.child,
      );
    }

    if (widget.sceneId.contains('circuit') && widget.layerType == 'actor') {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: 0.5 + (_controller.value * 0.5),
            child: child,
          );
        },
        child: widget.child,
      );
    }

    return widget.child;
  }
}
