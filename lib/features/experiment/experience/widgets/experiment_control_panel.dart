import 'package:flutter/material.dart';

import '../../runtime/object_registry.dart';
import '../../runtime/models/runtime_object_state.dart';
import '../../runtime/runtime_event.dart';
import '../../runtime/runtime_event_bus.dart';
import '../services/runtime_label_formatter.dart';

class ExperimentControlPanel extends StatelessWidget {
  final ObjectRegistry objectRegistry;
  final ValueChanged<String>? onFeedback;
  final RuntimeEventBus? eventBus;
  final RuntimeLabelFormatter formatter;

  const ExperimentControlPanel({
    super.key,
    required this.objectRegistry,
    this.onFeedback,
    this.eventBus,
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
        if (controls.isEmpty) {
          return const SizedBox.shrink();
        }
        return _PanelShell(
          title: 'Experiment Controls',
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final state = controls[index];
              if (state.objectType == 'slider') {
                return _SliderControl(
                  state: state,
                  registry: objectRegistry,
                  formatter: formatter,
                  onFeedback: onFeedback,
                  eventBus: eventBus,
                );
              }
              if (state.objectType == 'toggle') {
                return _ToggleControl(
                  state: state,
                  registry: objectRegistry,
                  formatter: formatter,
                  onFeedback: onFeedback,
                  eventBus: eventBus,
                );
              }
              return _ButtonControl(
                state: state,
                formatter: formatter,
                onFeedback: onFeedback,
                eventBus: eventBus,
              );
            },
            separatorBuilder: (_, _) => const Divider(height: 16),
            itemCount: controls.length,
          ),
        );
      },
    );
  }
}

class _SliderControl extends StatelessWidget {
  final RuntimeObjectState state;
  final ObjectRegistry registry;
  final RuntimeLabelFormatter formatter;
  final ValueChanged<String>? onFeedback;
  final RuntimeEventBus? eventBus;

  const _SliderControl({
    required this.state,
    required this.registry,
    required this.formatter,
    this.onFeedback,
    this.eventBus,
  });

  @override
  Widget build(BuildContext context) {
    final label = formatter.format(
      state.state['label']?.toString() ?? state.objectId,
    );
    final min = _double(state.state['min'], 0);
    final max = _double(state.state['max'], 100);
    final value = _double(state.state['value'], min).clamp(min, max).toDouble();
    return Column(
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
            Text(value.toStringAsFixed(1)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max <= min ? min + 1 : max,
          onChanged: (next) {
            registry.updateObjectState(state.objectId, 'value', next);
            _emitControlEvent(eventBus, 'SliderChanged', state.objectId, {
              'value': next,
            });
            onFeedback?.call('$label = ${next.toStringAsFixed(1)}');
          },
        ),
      ],
    );
  }
}

class _ToggleControl extends StatelessWidget {
  final RuntimeObjectState state;
  final ObjectRegistry registry;
  final RuntimeLabelFormatter formatter;
  final ValueChanged<String>? onFeedback;
  final RuntimeEventBus? eventBus;

  const _ToggleControl({
    required this.state,
    required this.registry,
    required this.formatter,
    this.onFeedback,
    this.eventBus,
  });

  @override
  Widget build(BuildContext context) {
    final label = formatter.format(
      state.state['label']?.toString() ?? state.objectId,
    );
    final value = state.state['value'] == true;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: (next) {
        registry.updateObjectState(state.objectId, 'value', next);
        _emitControlEvent(
          eventBus,
          next ? 'ToggleEnabled' : 'ToggleDisabled',
          state.objectId,
          {'value': next},
        );
        _emitControlEvent(eventBus, 'ToggleChanged', state.objectId, {
          'value': next,
        });
        onFeedback?.call('$label ${next ? 'on' : 'off'}');
      },
    );
  }
}

class _ButtonControl extends StatelessWidget {
  final RuntimeObjectState state;
  final RuntimeLabelFormatter formatter;
  final ValueChanged<String>? onFeedback;
  final RuntimeEventBus? eventBus;

  const _ButtonControl({
    required this.state,
    required this.formatter,
    this.onFeedback,
    this.eventBus,
  });

  @override
  Widget build(BuildContext context) {
    final label = formatter.format(
      state.state['label']?.toString() ?? state.objectId,
    );
    return FilledButton.icon(
      onPressed: () {
        _emitControlEvent(eventBus, 'ButtonPressed', state.objectId);
        onFeedback?.call('$label pressed');
      },
      icon: const Icon(Icons.touch_app_outlined),
      label: Text(label),
    );
  }
}

class _PanelShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _PanelShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

double _double(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

void _emitControlEvent(
  RuntimeEventBus? eventBus,
  String message,
  String objectId, [
  Map<String, dynamic> metadata = const {},
]) {
  eventBus?.emit(
    RuntimeEvent(
      id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: RuntimeEventType.custom,
      message: message,
      metadata: {'objectId': objectId, ...metadata},
    ),
  );
}
