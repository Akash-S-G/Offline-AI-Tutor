import 'package:flutter/material.dart';

import '../../../runtime/models/runtime_object_state.dart';

class RuntimeHud extends StatelessWidget {
  final List<RuntimeObjectState> displays;

  const RuntimeHud({super.key, required this.displays});

  @override
  Widget build(BuildContext context) {
    if (displays.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 16,
      left: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: displays.take(6).map((state) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _labelFor(state),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _valueFor(state),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

String _labelFor(RuntimeObjectState state) {
  return state.state['label']?.toString().isNotEmpty == true
      ? state.state['label'].toString()
      : _readableType(state.objectType);
}

String _valueFor(RuntimeObjectState state) {
  final unit = state.state['unit']?.toString() ?? '';
  final explicit =
      state.state['formattedValue'] ??
      state.state['formattedText'] ??
      state.state['text'];
  if (explicit != null && explicit.toString().isNotEmpty) {
    return unit.isEmpty ? explicit.toString() : '$explicit $unit';
  }
  final value =
      state.state['value'] ??
      state.state['progress'] ??
      state.state['normalizedValue'] ??
      state.state['magnitude'];
  if (value == null) return '';
  if (value is num) {
    final precision = _readInt(state.state['precision'], 1);
    final text = value.toDouble().toStringAsFixed(precision);
    return unit.isEmpty ? text : '$text $unit';
  }
  return unit.isEmpty ? value.toString() : '$value $unit';
}

String _readableType(String type) {
  final spaced = type.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

int _readInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
