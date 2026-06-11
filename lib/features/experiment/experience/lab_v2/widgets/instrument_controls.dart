import 'package:flutter/material.dart';

import '../../../runtime/models/runtime_object_state.dart';
import '../../../runtime/object_registry.dart';
import '../../../runtime/runtime_event.dart';
import '../../../runtime/runtime_event_bus.dart';
import '../instruments/lab_button.dart';
import '../instruments/lab_dial.dart';
import '../instruments/lab_switch.dart';
import '../../services/runtime_label_formatter.dart';

class InstrumentControls extends StatelessWidget {
  final ObjectRegistry objectRegistry;
  final RuntimeEventBus eventBus;
  final VoidCallback onRun;
  final VoidCallback onReset;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onRecordObservation;
  final VoidCallback? onInteraction;
  final RuntimeLabelFormatter formatter;
  final bool compact;
  final bool isRunning;
  final bool isPaused;
  final bool isPreparing;

  const InstrumentControls({
    super.key,
    required this.objectRegistry,
    required this.eventBus,
    required this.onRun,
    required this.onReset,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onRecordObservation,
    this.onInteraction,
    this.formatter = const RuntimeLabelFormatter(),
    this.compact = false,
    this.isRunning = false,
    this.isPaused = false,
    this.isPreparing = false,
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
          bottom: compact ? 18 : 86,
          right: 18,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 420 : 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...controls.take(compact ? 2 : 4).map(_controlFor),
                    _RunButton(
                      onRun: onRun,
                      onPause: onPause,
                      onResume: onResume,
                      isRunning: isRunning,
                      isPaused: isPaused,
                      isPreparing: isPreparing,
                    ),
                    if (isRunning || isPaused)
                      IconButton.filledTonal(
                        tooltip: 'Record Observation',
                        onPressed: onRecordObservation,
                        icon: const Icon(Icons.playlist_add_check),
                      ),
                    if (isRunning || isPaused)
                      IconButton.filledTonal(
                        tooltip: 'Stop',
                        onPressed: onStop,
                        icon: const Icon(Icons.stop),
                      ),
                    IconButton.filledTonal(
                      tooltip: 'Reset',
                      onPressed: onReset,
                      icon: const Icon(Icons.restart_alt),
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
      return _InstrumentDial(
        state: state,
        objectRegistry: objectRegistry,
        eventBus: eventBus,
        formatter: formatter,
        onInteraction: onInteraction,
      );
    }
    if (state.objectType == 'toggle') {
      return _InstrumentSwitch(
        state: state,
        objectRegistry: objectRegistry,
        eventBus: eventBus,
        formatter: formatter,
        onInteraction: onInteraction,
      );
    }
    return _InstrumentButton(
      state: state,
      eventBus: eventBus,
      formatter: formatter,
      onInteraction: onInteraction,
    );
  }
}

class _RunButton extends StatelessWidget {
  final VoidCallback onRun;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final bool isRunning;
  final bool isPaused;
  final bool isPreparing;

  const _RunButton({
    required this.onRun,
    this.onPause,
    this.onResume,
    required this.isRunning,
    required this.isPaused,
    required this.isPreparing,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isPreparing
        ? Icons.hourglass_top
        : isRunning
        ? Icons.pause
        : Icons.play_arrow;
    final label = isPreparing
        ? 'Preparing'
        : isRunning
        ? 'Pause'
        : isPaused
        ? 'Resume'
        : 'Run';
    final onPressed = isPreparing
        ? null
        : isRunning
        ? onPause
        : isPaused
        ? onResume
        : onRun;
    final color = isRunning
        ? const Color(0xFFF59E0B)
        : isPaused
        ? const Color(0xFF2563EB)
        : const Color(0xFF10B981);
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _InstrumentDial extends StatelessWidget {
  final RuntimeObjectState state;
  final ObjectRegistry objectRegistry;
  final RuntimeEventBus eventBus;
  final RuntimeLabelFormatter formatter;
  final VoidCallback? onInteraction;

  const _InstrumentDial({
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
    final unit = state.state['unit']?.toString();
    return SizedBox(
      width: 112,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LabDial(
            label: label,
            value: value,
            min: min,
            max: max,
            unit: unit,
            onChanged: _update,
          ),
        ],
      ),
    );
  }

  void _update(double next) {
    objectRegistry.updateObjectState(state.objectId, 'value', next);
    eventBus.emit(
      RuntimeEvent(
        id: 'SliderChanged_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: 'SliderChanged',
        metadata: {
          'objectId': state.objectId,
          'label': state.state['label']?.toString() ?? state.objectId,
          'value': next,
        },
      ),
    );
    onInteraction?.call();
  }
}

class _InstrumentSwitch extends StatelessWidget {
  final RuntimeObjectState state;
  final ObjectRegistry objectRegistry;
  final RuntimeEventBus eventBus;
  final RuntimeLabelFormatter formatter;
  final VoidCallback? onInteraction;

  const _InstrumentSwitch({
    required this.state,
    required this.objectRegistry,
    required this.eventBus,
    required this.formatter,
    this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final value = state.state['value'] == true;
    final label = formatter.format(
      state.state['label']?.toString() ?? state.objectId,
    );
    return LabSwitch(
      label: label,
      value: value,
      onChanged: (next) {
        objectRegistry.updateObjectState(state.objectId, 'value', next);
        eventBus.emit(
          RuntimeEvent(
            id: 'ToggleChanged_${DateTime.now().microsecondsSinceEpoch}',
            timestamp: DateTime.now(),
            type: RuntimeEventType.custom,
            message: 'ToggleChanged',
            metadata: {
              'objectId': state.objectId,
              'label': label,
              'value': next,
            },
          ),
        );
        onInteraction?.call();
      },
    );
  }
}

class _InstrumentButton extends StatelessWidget {
  final RuntimeObjectState state;
  final RuntimeEventBus eventBus;
  final RuntimeLabelFormatter formatter;
  final VoidCallback? onInteraction;

  const _InstrumentButton({
    required this.state,
    required this.eventBus,
    required this.formatter,
    this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final label = formatter.format(
      state.state['label']?.toString() ?? state.objectId,
    );
    return LabButton(
      label: label,
      onPressed: () {
        eventBus.emit(
          RuntimeEvent(
            id: 'ButtonPressed_${DateTime.now().microsecondsSinceEpoch}',
            timestamp: DateTime.now(),
            type: RuntimeEventType.custom,
            message: 'ButtonPressed',
            metadata: {'objectId': state.objectId, 'label': label},
          ),
        );
        onInteraction?.call();
      },
    );
  }
}

double _double(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
