import 'dart:async';

import 'package:flutter/material.dart';

import '../../../runtime/runtime_event.dart';
import '../../../runtime/runtime_event_bus.dart';

class ExperimentActivityFeed extends StatefulWidget {
  final RuntimeEventBus eventBus;
  final bool hidden;

  const ExperimentActivityFeed({
    super.key,
    required this.eventBus,
    this.hidden = false,
  });

  @override
  State<ExperimentActivityFeed> createState() => _ExperimentActivityFeedState();
}

class _ExperimentActivityFeedState extends State<ExperimentActivityFeed> {
  final List<String> _events = [];
  StreamSubscription<RuntimeEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.eventBus.stream.listen(_onEvent);
  }

  @override
  void didUpdateWidget(covariant ExperimentActivityFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventBus != widget.eventBus) {
      _subscription?.cancel();
      _subscription = widget.eventBus.stream.listen(_onEvent);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hidden || _events.isEmpty) return const SizedBox.shrink();
    return Positioned(
      left: 18,
      bottom: 96,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: _events
                  .take(5)
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        event,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _onEvent(RuntimeEvent event) {
    final label = _label(event);
    if (label == null || !mounted) return;
    setState(() {
      _events.insert(0, label);
      if (_events.length > 10) _events.removeLast();
    });
  }

  String? _label(RuntimeEvent event) {
    final name =
        event.metadata?['label']?.toString() ??
        event.metadata?['objectId']?.toString() ??
        event.metadata?['variableId']?.toString();
    switch (event.message) {
      case 'SliderChanged':
        return '${_pretty(name ?? 'Control')} changed';
      case 'ToggleChanged':
        return '${_pretty(name ?? 'Switch')} toggled';
      case 'ButtonPressed':
        return '${_pretty(name ?? 'Button')} pressed';
      case 'ObservationRecorded':
        return 'Observation recorded';
      case 'TrialCompleted':
        return 'Trial saved';
      case 'ConclusionGenerated':
        return 'Conclusion generated';
      case 'GraphUpdated':
        return 'Visual updated';
      default:
        return null;
    }
  }

  String _pretty(String raw) {
    return raw.replaceAll('_', ' ');
  }
}
