import 'dart:ui';
import 'package:flutter/material.dart';

/// Context passed to every [RuntimeEffect.tick] call.
/// Contains the full variable + behavior-output snapshot for the current frame.
class EffectContext {
  /// Raw simulation variables (e.g. var_length → 2.0)
  final Map<String, double> variables;

  /// Outputs from all behaviors this frame (e.g. behavior_angle → 0.4)
  final Map<String, double> behaviorOutputs;

  /// Resolved visual-mapping properties (e.g. glow_intensity → 0.8)
  final Map<String, double> properties;

  /// Elapsed simulation time in seconds.
  final double time;

  /// Canvas size available for drawing.
  final Size size;

  /// The canvas to draw on.
  final Canvas canvas;

  const EffectContext({
    required this.variables,
    required this.behaviorOutputs,
    required this.properties,
    required this.time,
    required this.size,
    required this.canvas,
  });

  /// Convenience: read from variables, then behaviorOutputs, then properties.
  double get(String key, {double defaultValue = 0.0}) =>
      variables[key] ?? behaviorOutputs[key] ?? properties[key] ?? defaultValue;

  /// Convenience: read a property with a fallback.
  double prop(String key, {double defaultValue = 0.0}) =>
      properties[key] ?? defaultValue;
}

/// Base interface for all visual effects.
/// An effect draws itself onto a [Canvas] each frame using data from [EffectContext].
abstract class RuntimeEffect {
  /// Unique type identifier matching the JSON declaration (e.g. 'motion_trail').
  String get type;

  /// Draw this effect. Called every animation frame.
  void tick(EffectContext context, Map<String, dynamic> params);
}
