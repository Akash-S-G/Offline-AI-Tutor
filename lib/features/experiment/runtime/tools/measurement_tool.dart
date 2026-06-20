import 'package:flutter/material.dart';
import '../../runtime/runtime_world.dart';

/// Base interface for all on-screen measurement tools.
abstract class MeasurementTool {
  String get type;

  /// Build the on-screen overlay widget for this tool.
  Widget buildOverlay(RuntimeWorld world, BuildContext context);
}
