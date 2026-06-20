import 'package:flutter/material.dart';
import '../../runtime/runtime_world.dart';
import 'measurement_tool.dart';
import 'stopwatch_tool.dart';
import 'ruler_tool.dart';

/// Central registry mapping tool type strings to [MeasurementTool] instances.
class MeasurementRegistry {
  static final Map<String, MeasurementTool> _registry = {};

  static void initialize() {
    register(StopwatchTool());
    register(RulerTool());
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
    final resolved = tools
        .map((t) => MeasurementRegistry.resolve(t as String))
        .whereType<MeasurementTool>()
        .toList();

    if (resolved.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: resolved
          .map((tool) => tool.buildOverlay(world, context))
          .toList(),
    );
  }
}
