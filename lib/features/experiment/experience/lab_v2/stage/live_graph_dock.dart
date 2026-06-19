import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../runtime/runtime_world.dart';
import '../../services/runtime_label_formatter.dart';

class LiveGraphDock extends StatelessWidget {
  final RuntimeWorld world;
  final RuntimeLabelFormatter formatter;

  const LiveGraphDock({
    super.key,
    required this.world,
    this.formatter = const RuntimeLabelFormatter(),
  });

  @override
  Widget build(BuildContext context) {
    final variables = world.variables.allRuntimeVariables.values.toList();
    final primary = variables.isEmpty ? null : variables.first;
    final graphObjects = world.objects.allObjectStates
        .where((state) => _graphTypes.contains(state.objectType))
        .toList(growable: false);
    return Positioned(
      top: 64,
      right: 16,
      bottom: 80,
      width: MediaQuery.sizeOf(context).width * 0.24,
      child: IgnorePointer(
        ignoring: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xEE0F172A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.show_chart,
                      color: Color(0xFF38BDF8),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        graphObjects.isEmpty
                            ? 'Live Graph'
                            : formatter.format(graphObjects.first.objectType),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomPaint(
                    painter: _MiniGraphPainter(
                      values: _valuesFor(primary?.id),
                      lineColor: const Color(0xFF38BDF8),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  primary == null
                      ? 'Waiting for readings'
                      : '${formatter.format(primary.name)}  ${primary.value}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<double> _valuesFor(String? variableId) {
    if (variableId == null) {
      return List<double>.generate(
        24,
        (index) => 0.5 + math.sin(index / 2.4) * 0.25,
      );
    }
    final measurements = world.measurementStore.getMeasurements(variableId);
    if (measurements.isNotEmpty) {
      return measurements
          .map((measurement) => measurement.value)
          .whereType<num>()
          .map((value) => value.toDouble())
          .take(40)
          .toList(growable: false);
    }
    final value = world.variables.allRuntimeVariables[variableId]?.value;
    final base = value is num ? value.toDouble() : 1.0;
    return List<double>.generate(
      24,
      (index) => base + math.sin(index / 2.8) * math.max(1, base.abs() * 0.08),
    );
  }

  static const _graphTypes = {
    'lineGraph',
    'scatterPlot',
    'barChart',
    'oscilloscope',
    'spectrumAnalyzer',
    'vectorVisualizer',
  };
}

class _MiniGraphPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;

  const _MiniGraphPainter({required this.values, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (values.length < 2) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = (maxValue - minValue).abs() < 0.001 ? 1 : maxValue - minValue;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minValue) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniGraphPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}
