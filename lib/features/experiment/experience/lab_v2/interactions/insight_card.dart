import 'dart:async';

import 'package:flutter/material.dart';

import '../../../runtime/runtime_event.dart';
import '../../../runtime/runtime_event_bus.dart';

class InsightCard extends StatefulWidget {
  final RuntimeEventBus eventBus;
  final bool hidden;

  const InsightCard({super.key, required this.eventBus, this.hidden = false});

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  StreamSubscription<RuntimeEvent>? _subscription;
  String? _insight;

  @override
  void initState() {
    super.initState();
    _subscription = widget.eventBus.stream.listen((event) {
      if (event.message != 'ConclusionGenerated') return;
      if (!mounted) return;
      setState(() {
        _insight =
            event.metadata?['conclusion']?.toString() ??
            'A trend was detected in your results.';
      });
    });
  }

  @override
  void didUpdateWidget(covariant InsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventBus != widget.eventBus) {
      _subscription?.cancel();
      _subscription = widget.eventBus.stream.listen((event) {
        if (event.message != 'ConclusionGenerated') return;
        if (!mounted) return;
        setState(() {
          _insight =
              event.metadata?['conclusion']?.toString() ??
              'A trend was detected in your results.';
        });
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hidden) return const SizedBox.shrink();
    if (_insight == null) return const SizedBox.shrink();
    return Positioned(
      right: 18,
      top: 96,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B)),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 18),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Insight',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(_insight!, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
