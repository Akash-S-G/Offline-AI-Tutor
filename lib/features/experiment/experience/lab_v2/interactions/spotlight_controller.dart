import 'dart:async';

import 'package:flutter/material.dart';

import '../../../runtime/runtime_event.dart';
import '../../../runtime/runtime_event_bus.dart';

class SpotlightController extends StatefulWidget {
  final RuntimeEventBus eventBus;
  final bool hidden;

  const SpotlightController({
    super.key,
    required this.eventBus,
    this.hidden = false,
  });

  @override
  State<SpotlightController> createState() => _SpotlightControllerState();
}

class _SpotlightControllerState extends State<SpotlightController> {
  StreamSubscription<RuntimeEvent>? _subscription;
  Timer? _hideTimer;
  String? _label;

  @override
  void initState() {
    super.initState();
    _subscription = widget.eventBus.stream.listen(_onEvent);
  }

  @override
  void didUpdateWidget(covariant SpotlightController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventBus != widget.eventBus) {
      _subscription?.cancel();
      _subscription = widget.eventBus.stream.listen(_onEvent);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hidden || _label == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          builder: (context, value, _) {
            return Stack(
              children: [
                ColoredBox(color: Colors.black.withValues(alpha: 0.22 * value)),
                Center(
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFACC15),
                        width: 4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66FACC15),
                          blurRadius: 28,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 74,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Text(
                          _label!,
                          style: const TextStyle(
                            color: Color(0xFF422006),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onEvent(RuntimeEvent event) {
    if (event.message != 'VisualFocusTriggered') return;
    if (!mounted) return;
    final reason = event.metadata?['reason']?.toString();
    final target = event.metadata?['targetId']?.toString();
    setState(() => _label = reason ?? target ?? 'Focus here');
    final durationMs = event.metadata?['durationMs'];
    final duration = Duration(
      milliseconds: durationMs is num ? durationMs.toInt() : 3000,
    );
    _hideTimer?.cancel();
    _hideTimer = Timer(duration, () {
      if (mounted) setState(() => _label = null);
    });
  }
}
