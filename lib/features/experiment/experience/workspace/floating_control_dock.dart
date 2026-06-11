import 'package:flutter/material.dart';

import '../../runtime/models/runtime_object_state.dart';
import '../../runtime/object_registry.dart';
import '../../runtime/runtime_event.dart';
import '../../runtime/runtime_event_bus.dart';
import '../services/runtime_label_formatter.dart';

class FloatingControlDock extends StatelessWidget {
  final ObjectRegistry objectRegistry;
  final RuntimeEventBus eventBus;
  final VoidCallback onRun;
  final VoidCallback onReset;
  final VoidCallback? onInteraction;
  final RuntimeLabelFormatter formatter;

  const FloatingControlDock({
    super.key,
    required this.objectRegistry,
    required this.eventBus,
    required this.onRun,
    required this.onReset,
    this.onInteraction,
    this.formatter = const RuntimeLabelFormatter(),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: objectRegistry,
      builder: (context, _) {
        final controls = objectRegistry.allObjectStates
            .where((state) => state.visible)
            .where(
              (state) =>
                  {'slider', 'button', 'toggle'}.contains(state.objectType),
            )
            .toList(growable: false);
        return Positioned(
          bottom: 20,
          right: 20,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...controls.take(3).map(_controlFor),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onRun,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Run'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Reset',
                          onPressed: onReset,
                          icon: const Icon(Icons.restart_alt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _controlFor(RuntimeObjectState state) {
    if (state.objectType == 'slider') {
      return _DockSlider(
        state: state,
        objectRegistry: objectRegistry,
        eventBus: eventBus,
        formatter: formatter,
        onInteraction: onInteraction,
      );
    }
    if (state.objectType == 'toggle') {
      final value = state.state['value'] == true;
      final label = formatter.format(
        state.state['label']?.toString() ?? state.objectId,
      );
      return SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged: (next) {
          objectRegistry.updateObjectState(state.objectId, 'value', next);
          _emit('ToggleChanged', state.objectId, {'value': next});
          onInteraction?.call();
        },
      );
    }
    final label = formatter.format(
      state.state['label']?.toString() ?? state.objectId,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () {
          _emit('ButtonPressed', state.objectId);
          onInteraction?.call();
        },
        child: Text(label),
      ),
    );
  }

  void _emit(
    String message,
    String objectId, [
    Map<String, dynamic> metadata = const {},
  ]) {
    eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: {'objectId': objectId, ...metadata},
      ),
    );
  }
}

class _DockSlider extends StatelessWidget {
  final RuntimeObjectState state;
  final ObjectRegistry objectRegistry;
  final RuntimeEventBus eventBus;
  final RuntimeLabelFormatter formatter;
  final VoidCallback? onInteraction;

  const _DockSlider({
    required this.state,
    required this.objectRegistry,
    required this.eventBus,
    required this.formatter,
    this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final min = _double(state.state['min'], 0);
    final max = _double(state.state['max'], 100);
    final value = _double(state.state['value'], min).clamp(min, max).toDouble();
    final label = formatter.format(
      state.state['label']?.toString() ?? state.objectId,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 180),
                child: Text(value.toStringAsFixed(1)),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max <= min ? min + 1 : max,
            onChanged: (next) {
              objectRegistry.updateObjectState(state.objectId, 'value', next);
              eventBus.emit(
                RuntimeEvent(
                  id: 'SliderChanged_${DateTime.now().microsecondsSinceEpoch}',
                  timestamp: DateTime.now(),
                  type: RuntimeEventType.custom,
                  message: 'SliderChanged',
                  metadata: {'objectId': state.objectId, 'value': next},
                ),
              );
              onInteraction?.call();
            },
          ),
        ],
      ),
    );
  }
}

double _double(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
