import 'dart:async';

import 'package:flutter/material.dart';

import '../../../guided_runtime/engine/guided_experiment_engine.dart';

class JourneyProgress extends StatefulWidget {
  final GuidedExperimentEngine? guidedEngine;
  final bool compact;

  const JourneyProgress({
    super.key,
    required this.guidedEngine,
    this.compact = false,
  });

  @override
  State<JourneyProgress> createState() => _JourneyProgressState();
}

class _JourneyProgressState extends State<JourneyProgress> {
  bool _expanded = false;
  Timer? _collapseTimer;
  int _lastCompletedTasks = 0;

  @override
  void initState() {
    super.initState();
    _lastCompletedTasks = widget.guidedEngine?.state.completedTasks.length ?? 0;
    widget.guidedEngine?.addListener(_onGuidedStateChanged);
  }

  @override
  void didUpdateWidget(covariant JourneyProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guidedEngine != widget.guidedEngine) {
      oldWidget.guidedEngine?.removeListener(_onGuidedStateChanged);
      _lastCompletedTasks =
          widget.guidedEngine?.state.completedTasks.length ?? 0;
      widget.guidedEngine?.addListener(_onGuidedStateChanged);
    }
  }

  @override
  void dispose() {
    widget.guidedEngine?.removeListener(_onGuidedStateChanged);
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact || !_expanded;
    final state = widget.guidedEngine?.state;
    final tasks = state?.mission?.tasks ?? const [];
    final labels = tasks.isEmpty
        ? const ['Predict', 'Run', 'Observe', 'Compare', 'Conclude']
        : tasks.take(5).map((task) => task.title).toList(growable: false);
    final completed = state?.completedTasks.length ?? 0;
    return GestureDetector(
      onTap: () {
        setState(() => _expanded = !_expanded);
        if (_expanded) _scheduleCollapse();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(compact ? 999 : 16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 10),
          child: compact
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.route_outlined,
                      size: 18,
                      color: Color(0xFF0F766E),
                    ),
                    if (completed > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '$completed',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      _JourneyItem(
                        label: labels[i],
                        complete:
                            tasks.isNotEmpty &&
                            (state?.completedTasks.contains(tasks[i].id) ??
                                false),
                        active:
                            tasks.isNotEmpty &&
                            state?.currentTask?.id == tasks[i].id,
                        showLine: i < labels.length - 1,
                        compact: false,
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  void _onGuidedStateChanged() {
    final completed = widget.guidedEngine?.state.completedTasks.length ?? 0;
    if (completed <= _lastCompletedTasks) return;
    _lastCompletedTasks = completed;
    if (!mounted) return;
    setState(() => _expanded = true);
    _scheduleCollapse();
  }

  void _scheduleCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _expanded = false);
    });
  }
}

class _JourneyItem extends StatelessWidget {
  final String label;
  final bool complete;
  final bool active;
  final bool showLine;
  final bool compact;

  const _JourneyItem({
    required this.label,
    required this.complete,
    required this.active,
    required this.showLine,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? const Color(0xFF16A34A)
        : active
        ? const Color(0xFF0F766E)
        : const Color(0xFF94A3B8);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            Icon(
              complete
                  ? Icons.check_circle
                  : active
                  ? Icons.circle
                  : Icons.radio_button_unchecked,
              size: 17,
              color: color,
            ),
            if (showLine)
              Container(
                width: 2,
                height: compact ? 12 : 20,
                color: color.withValues(alpha: 0.35),
              ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(width: 7),
          SizedBox(
            width: 120,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
