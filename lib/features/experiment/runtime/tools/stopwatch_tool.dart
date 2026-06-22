import 'package:flutter/material.dart';
import '../../runtime/runtime_world.dart';
import 'measurement_tool.dart';

/// Floating on-screen stopwatch.
/// Student taps Start/Stop to measure elapsed time (e.g. pendulum period).
class StopwatchTool implements MeasurementTool {
  @override
  String get type => 'stopwatch';

  @override
  Widget buildOverlay(RuntimeWorld world, BuildContext context, [Map<String, dynamic>? config]) {
    return const Positioned(
      top: 16,
      right: 16,
      child: _StopwatchWidget(),
    );
  }
}

class _StopwatchWidget extends StatefulWidget {
  const _StopwatchWidget();

  @override
  State<_StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<_StopwatchWidget> {
  final Stopwatch _stopwatch = Stopwatch();
  bool _running = false;

  String get _display {
    final ms = _stopwatch.elapsedMilliseconds;
    final s = (ms / 1000).floor();
    final decimal = (ms % 1000) ~/ 10;
    return '$s.${decimal.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([]),
      builder: (context, child) => _build(),
    );
  }

  Widget _build() {
    if (_running) {
      // Rebuild every ~50ms when running
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _running) setState(() {});
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: Colors.tealAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                _display,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _btn(
                _running ? 'Stop' : 'Start',
                _running ? Colors.red : Colors.tealAccent,
                () => setState(() {
                  _running ? _stopwatch.stop() : _stopwatch.start();
                  _running = !_running;
                }),
              ),
              const SizedBox(width: 8),
              _btn('Reset', Colors.white38, () => setState(() {
                _stopwatch.reset();
                _running = false;
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
