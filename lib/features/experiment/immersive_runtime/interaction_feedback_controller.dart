import 'package:flutter/material.dart';

class InteractionFeedbackController extends StatefulWidget {
  final Widget child;

  const InteractionFeedbackController({
    super.key,
    required this.child,
  });

  @override
  State<InteractionFeedbackController> createState() => _InteractionFeedbackControllerState();
}

class _InteractionFeedbackControllerState extends State<InteractionFeedbackController>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _handleTapDown,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_tapPosition != null)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  left: _tapPosition!.dx - 30,
                  top: _tapPosition!.dy - 30,
                  child: Opacity(
                    opacity: 1.0 - _controller.value,
                    child: Transform.scale(
                      scale: 0.5 + (_controller.value * 1.5),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
