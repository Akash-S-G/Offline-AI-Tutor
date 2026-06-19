import 'dart:async';

import 'package:flutter/material.dart';

import '../../../guided_runtime/engine/guided_experiment_engine.dart';
import '../../../runtime/runtime_event.dart';
import '../../../runtime/runtime_event_bus.dart';

class ExperimentNarrator extends StatefulWidget {
  final RuntimeEventBus eventBus;
  final GuidedExperimentEngine? guidedEngine;
  final bool hidden;

  const ExperimentNarrator({
    super.key,
    required this.eventBus,
    this.guidedEngine,
    this.hidden = false,
  });

  @override
  State<ExperimentNarrator> createState() => _ExperimentNarratorState();
}

class _ExperimentNarratorState extends State<ExperimentNarrator> {
  StreamSubscription<RuntimeEvent>? _subscription;
  Timer? _collapseTimer;
  String _message = 'Begin the investigation.';
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _subscription = widget.eventBus.stream.listen(_onEvent);
    _scheduleCollapse();
  }

  @override
  void didUpdateWidget(covariant ExperimentNarrator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventBus != widget.eventBus) {
      _subscription?.cancel();
      _subscription = widget.eventBus.stream.listen(_onEvent);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hidden) return const SizedBox.shrink();
    final task = widget.guidedEngine?.state.currentTask?.title;
    return Positioned(
      top: 62,
      left: 18,
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded) _scheduleCollapse();
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: DecoratedBox(
              key: ValueKey('$_expanded:$_message'),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(_expanded ? 14 : 999),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _expanded ? 12 : 10,
                  vertical: _expanded ? 8 : 10,
                ),
                child: _expanded
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(
                          task == null ? _message : 'Task: $task  •  $_message',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: Color(0xFF0F766E),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onEvent(RuntimeEvent event) {
    final next = _messageFor(event);
    if (next == null || !mounted) return;
    setState(() {
      _message = next;
      _expanded = true;
    });
    _scheduleCollapse();
  }

  void _scheduleCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _expanded = false);
    });
  }

  String? _messageFor(RuntimeEvent event) {
    final label =
        event.metadata?['label']?.toString() ??
        event.metadata?['objectId']?.toString() ??
        event.metadata?['variableId']?.toString();
    final value = event.metadata?['value'];
    switch (event.message) {
      case 'SliderChanged':
        return '${_pretty(label ?? 'Control')} changed to ${_format(value)}. Watch the experiment respond.';
      case 'VisualNarrationShown':
        return event.metadata?['message']?.toString();
      case 'ToggleChanged':
        return '${_pretty(label ?? 'Switch')} changed state.';
      case 'ObservationRecorded':
        return 'Observation captured. Compare it with your next trial.';
      case 'TrialCompleted':
        return 'Trial saved. Run another trial to compare results.';
      case 'ConclusionGenerated':
        return 'Insight ready. Review your conclusion and evidence.';
      default:
        return null;
    }
  }

  String _pretty(String raw) => raw.replaceAll('_', ' ');

  String _format(dynamic value) {
    if (value is num) return value.toStringAsFixed(1);
    return value?.toString() ?? '';
  }
}
