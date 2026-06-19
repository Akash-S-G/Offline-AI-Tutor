import 'dart:async';

import 'package:flutter/material.dart';

import '../../../runtime/runtime_event.dart';
import '../../../runtime/runtime_event_bus.dart';

class CauseEffectCard extends StatefulWidget {
  final RuntimeEventBus eventBus;
  final bool hidden;

  const CauseEffectCard({
    super.key,
    required this.eventBus,
    this.hidden = false,
  });

  @override
  State<CauseEffectCard> createState() => _CauseEffectCardState();
}

class _CauseEffectCardState extends State<CauseEffectCard> {
  StreamSubscription<RuntimeEvent>? _subscription;
  Timer? _hideTimer;
  String? _cause;
  String? _effect;

  @override
  void initState() {
    super.initState();
    _subscription = widget.eventBus.stream.listen(_onEvent);
  }

  @override
  void didUpdateWidget(covariant CauseEffectCard oldWidget) {
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
    if (widget.hidden || _cause == null || _effect == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 58,
      left: 16,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: DecoratedBox(
            key: ValueKey('$_cause:$_effect'),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _cause!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'causes',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _effect!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onEvent(RuntimeEvent event) {
    final pair = _causeEffectFor(event);
    if (pair == null || !mounted) return;
    setState(() {
      _cause = pair.$1;
      _effect = pair.$2;
    });
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _cause = null;
        _effect = null;
      });
    });
  }

  (String, String)? _causeEffectFor(RuntimeEvent event) {
    final label = _pretty(
      event.metadata?['label']?.toString() ??
          event.metadata?['objectId']?.toString() ??
          event.metadata?['variableId']?.toString() ??
          'Control',
    );
    final value = _format(event.metadata?['value']);
    switch (event.message) {
      case 'SliderChanged':
        return ('$label changed$value', 'the experiment responds');
      case 'ToggleChanged':
        return ('$label switched', 'the setup updates');
      case 'ButtonPressed':
        return ('$label pressed', 'the trial advances');
      case 'VisualResponseTriggered':
        final response =
            event.metadata?['response']?.toString() ?? 'visual response';
        return ('$label changed', _pretty(response));
      case 'ObservationRecorded':
        return ('Observation captured', 'evidence added to findings');
      case 'TrialCompleted':
        return ('Trial saved', 'results ready to compare');
      case 'ConclusionGenerated':
        return ('Conclusion generated', 'finding ready for report');
      default:
        return null;
    }
  }

  String _pretty(String raw) => raw.replaceAll('_', ' ');

  String _format(dynamic value) {
    if (value == null) return '';
    if (value is num) return ' to ${value.toStringAsFixed(1)}';
    final text = value.toString();
    return text.isEmpty ? '' : ' to $text';
  }
}
