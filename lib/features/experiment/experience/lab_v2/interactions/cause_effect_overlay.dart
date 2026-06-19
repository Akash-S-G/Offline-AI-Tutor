import 'dart:async';

import 'package:flutter/material.dart';

import '../../../runtime/runtime_event.dart';
import '../../../runtime/runtime_event_bus.dart';

class CauseEffectOverlay extends StatefulWidget {
  final RuntimeEventBus eventBus;
  final bool hidden;

  const CauseEffectOverlay({
    super.key,
    required this.eventBus,
    this.hidden = false,
  });

  @override
  State<CauseEffectOverlay> createState() => _CauseEffectOverlayState();
}

class _CauseEffectOverlayState extends State<CauseEffectOverlay> {
  StreamSubscription<RuntimeEvent>? _subscription;
  int _pulse = 0;
  String _label = '';

  @override
  void initState() {
    super.initState();
    _subscription = widget.eventBus.stream.listen(_onEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hidden || _pulse == 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(_pulse),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 850),
          builder: (context, value, _) {
            return Stack(
              children: [
                Center(
                  child: Transform.scale(
                    scale: 0.7 + value * 1.4,
                    child: Opacity(
                      opacity: (1 - value).clamp(0, 1),
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981),
                            width: 5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: (1 - value * 0.6).clamp(0, 1),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Text(
                            _label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
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
    if (event.message != 'VisualResponseTriggered' &&
        event.message != 'SliderChanged' &&
        event.message != 'ToggleChanged' &&
        event.message != 'ButtonPressed') {
      return;
    }
    if (!mounted) return;
    setState(() {
      _pulse++;
      final label =
          event.metadata?['response']?.toString() ??
          event.metadata?['label']?.toString() ??
          event.metadata?['objectId']?.toString() ??
          'Control';
      _label = event.message == 'VisualResponseTriggered'
          ? label
          : '${label.replaceAll('_', ' ')} affected the lab';
    });
  }
}
