import 'package:flutter/material.dart';
import '../../runtime/runtime_world.dart';
import 'measurement_tool.dart';
import 'stopwatch_tool.dart';
import 'ruler_tool.dart';
import 'numeric_measurement_tool.dart';

/// Central registry mapping tool type strings to [MeasurementTool] instances.
class MeasurementRegistry {
  static final Map<String, MeasurementTool> _registry = {};

  static void initialize() {
    register(StopwatchTool());
    register(RulerTool());
    register(NumericMeasurementTool());
  }

  static void register(MeasurementTool tool) {
    _registry[tool.type] = tool;
  }

  static MeasurementTool? resolve(String type) => _registry[type];
}

/// Widget that reads a tools list from the blueprint and mounts overlays.
class ToolOverlay extends StatelessWidget {
  final List<dynamic> tools;
  final RuntimeWorld world;

  const ToolOverlay({super.key, required this.tools, required this.world});

  @override
  Widget build(BuildContext context) {
    if (tools.isEmpty) return const SizedBox.shrink();

    final List<Widget> overlays = [];

    for (final t in tools) {
      String type;
      Map<String, dynamic>? config;

      if (t is String) {
        type = t;
      } else if (t is Map) {
        type = t['type'] as String;
        config = Map<String, dynamic>.from(t);
      } else {
        continue;
      }

      final tool = MeasurementRegistry.resolve(type);
      if (tool != null) {
        overlays.add(tool.buildOverlay(world, context, config));
      }
    }

    if (overlays.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: overlays,
    );
  }
}
