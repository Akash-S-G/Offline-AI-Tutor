import 'package:flutter/material.dart';

class LabJoystick extends StatelessWidget {
  final String label;
  final Offset value;
  final ValueChanged<Offset> onChanged;

  const LabJoystick({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              final next = value + details.delta / 36;
              onChanged(
                Offset(
                  next.dx.clamp(-1, 1).toDouble(),
                  next.dy.clamp(-1, 1).toDouble(),
                ),
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E293B),
                border: Border.all(color: const Color(0xFF64748B)),
              ),
              child: SizedBox(
                width: 62,
                height: 62,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(value.dx * 18, value.dy * 18),
                    child: const Icon(Icons.circle, color: Color(0xFF10B981)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
