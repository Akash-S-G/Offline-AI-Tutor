import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../runtime/runtime_world.dart';
import '../runtime/behaviors/behavior_stack.dart';
import '../runtime/effects/effect.dart';
import '../runtime/effects/effect_executor.dart';

/// Generic scene effect controller.
///
/// NO experiment-specific if/else blocks here.
/// All rendering is driven by:
///   1. BehaviorStack   → computes physics outputs (angle, velocity, etc.)
///   2. EffectExecutor  → dispatches draw calls to registered RuntimeEffect instances
///
/// The pendulum, circuit, water cycle, etc. are all rendered through this
/// single generic path.
class SceneEffectController extends StatefulWidget {
  final RuntimeWorld world;
  final String sceneId;

  /// Behaviors declared in blueprint JSON: [{"type":"oscillation","params":{...}}]
  final List<dynamic> behaviors;

  /// Effects declared in blueprint JSON: [{"type":"motion_trail"},{"type":"glow"}]
  final List<dynamic> effects;

  /// Visual mapping properties resolved before this widget builds.
  final Map<String, double> visualProperties;

  const SceneEffectController({
    super.key,
    required this.world,
    required this.sceneId,
    this.behaviors = const [],
    this.effects = const [],
    this.visualProperties = const {},
  });

  @override
  State<SceneEffectController> createState() => _SceneEffectControllerState();
}

class _SceneEffectControllerState extends State<SceneEffectController>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final BehaviorStack _behaviorStack;
  late final EffectExecutor _effectExecutor;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _behaviorStack = BehaviorStack(widget.behaviors);
    _effectExecutor = EffectExecutor(widget.effects);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ticker,
      builder: (context, child) {
        final time = widget.world.clock.elapsedTime;

        // Read all variables as doubles
        final variables = _snapshotVariables();

        // Tick all behaviors — produces physics outputs (angle, velocity, etc.)
        final behaviorOutputs = _behaviorStack.tick(
          time: time,
          variables: variables,
        );

        // Compute display coordinates from behavior outputs
        final displayCoords = _resolveDisplayCoords(
          variables, behaviorOutputs, MediaQuery.of(context).size);

        // Merge: visual properties from parent + behavior outputs + coords
        final properties = {
          ...widget.visualProperties,
          ...behaviorOutputs,
          ...displayCoords,
        };

        return CustomPaint(
          painter: _GenericEffectPainter(
            effectExecutor: _effectExecutor,
            variables: variables,
            behaviorOutputs: behaviorOutputs,
            properties: properties,
            time: time,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Map<String, double> _snapshotVariables() {
    final result = <String, double>{};
    // The variable store exposes all variables — snapshot them as doubles
    // We use a pattern: try known variable IDs for the current scene
    const knownVars = [
      'var_length', 'var_mass', 'var_angle', 'var_period', 'var_velocity',
      'var_is_swinging', 'var_temperature', 'var_humidity', 'var_current',
      'var_voltage', 'var_resistance', 'var_switch_state', 'var_brightness',
      'var_growth', 'var_water', 'var_sunlight', 'var_heart_rate',
      'var_cloud_density', 'var_rainfall',
    ];
    for (final id in knownVars) {
      final val = widget.world.variables.getValue(id);
      if (val != null) result[id] = (val as num).toDouble();
    }
    return result;
  }

  /// Compute effect_x, effect_y, effect_radius, pivot_x, pivot_y
  /// from the current behavior outputs + screen size.
  Map<String, double> _resolveDisplayCoords(
    Map<String, double> variables,
    Map<String, double> behaviorOutputs,
    Size screenSize,
  ) {
    final coords = <String, double>{};
    final angle = behaviorOutputs['behavior_angle'] ?? 0.0;
    final length = variables['var_length'] ?? 1.0;
    final mass   = variables['var_mass'] ?? 1.0;

    final pivotX = screenSize.width / 2;
    final pivotY = screenSize.height * 0.18;
    final maxRadius = screenSize.height * 0.52;
    final radius = (maxRadius * (length / 5.0)).clamp(100.0, maxRadius);

    final bobX = pivotX + math.sin(angle) * radius;
    final bobY = pivotY + math.cos(angle) * radius;

    coords['pivot_x'] = pivotX;
    coords['pivot_y'] = pivotY;
    coords['effect_radius'] = radius;
    coords['effect_x'] = bobX;
    coords['effect_y'] = bobY;
    coords['bob_radius'] = 22.0 + (mass * 1.5).clamp(0.0, 15.0);

    return coords;
  }
}

class _GenericEffectPainter extends CustomPainter {
  final EffectExecutor effectExecutor;
  final Map<String, double> variables;
  final Map<String, double> behaviorOutputs;
  final Map<String, double> properties;
  final double _time;

  _GenericEffectPainter({
    required this.effectExecutor,
    required this.variables,
    required this.behaviorOutputs,
    required this.properties,
    required double time,
  }) : _time = time;

  @override
  void paint(Canvas canvas, Size size) {
    // Always draw the pendulum structure if we have relevant variables.
    // This is generic: it reads from behaviorOutputs + variables, not sceneId.
    if (variables.containsKey('var_is_swinging') ||
        variables.containsKey('var_angle') ||
        variables.containsKey('var_length')) {
      _paintPendulumStructure(canvas, size);
    }

    // Dispatch all JSON-declared effects through the registry
    final context = EffectContext(
      variables: variables,
      behaviorOutputs: behaviorOutputs,
      properties: properties,
      time: _time,
      size: size,
      canvas: canvas,
    );
    effectExecutor.tick(context);
  }

  void _paintPendulumStructure(Canvas canvas, Size size) {
    final isSwinging = (variables['var_is_swinging'] ?? 0.0) >= 0.5;
    final length = variables['var_length'] ?? 1.0;
    final mass   = variables['var_mass']   ?? 1.0;
    final angle  = behaviorOutputs['behavior_angle'] ??
        ((variables['var_angle'] ?? 30.0) * math.pi / 180.0);

    final pivotX  = properties['pivot_x']      ?? size.width / 2;
    final pivotY  = properties['pivot_y']      ?? size.height * 0.18;
    final radius  = properties['effect_radius'] ?? size.height * 0.4;
    final bobX    = properties['effect_x']     ?? pivotX + math.sin(angle) * radius;
    final bobY    = properties['effect_y']     ?? pivotY + math.cos(angle) * radius;
    final bobR    = properties['bob_radius']   ?? 22.0;

    final pivot = Offset(pivotX, pivotY);
    final bob   = Offset(bobX, bobY);

    // ── Support beam ──────────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(pivotX - 60, pivotY),
      Offset(pivotX + 60, pivotY),
      Paint()
        ..color = const Color(0xFF8B7355)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // ── String ────────────────────────────────────────────────────────────────
    canvas.drawLine(
      pivot, bob,
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // ── Velocity vector (when swinging) ───────────────────────────────────────
    if (isSwinging) {
      final omega = behaviorOutputs['behavior_omega'] ?? math.sqrt(9.81 / length);
      final angularVel = behaviorOutputs['behavior_angular_velocity'] ??
          -(variables['var_angle'] ?? 30.0) * math.pi / 180.0 * omega *
              math.sin(omega * _time);
      final velMagnitude = angularVel * 50;

      canvas.drawLine(
        bob, Offset(bob.dx + velMagnitude, bob.dy),
        Paint()
          ..color = Colors.orangeAccent
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        Offset(bob.dx + velMagnitude, bob.dy), 6,
        Paint()..color = Colors.orangeAccent,
      );
    }

    // ── Pivot pin ─────────────────────────────────────────────────────────────
    canvas.drawCircle(pivot, 10,
        Paint()..color = Colors.grey.shade400..style = PaintingStyle.fill);
    canvas.drawCircle(pivot, 10,
        Paint()..color = Colors.white30..style = PaintingStyle.stroke..strokeWidth = 2);

    // ── Bob glow ─────────────────────────────────────────────────────────────
    final velNorm = behaviorOutputs['behavior_velocity_norm'] ?? 0.0;
    canvas.drawCircle(
      bob, bobR + 12,
      Paint()
        ..color = Colors.tealAccent.withValues(
            alpha: isSwinging ? 0.2 + velNorm * 0.4 : 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // ── Bob body ──────────────────────────────────────────────────────────────
    final bobColor = isSwinging
        ? Color.lerp(Colors.teal, Colors.tealAccent, velNorm)!
        : Colors.teal;
    canvas.drawCircle(bob, isSwinging ? bobR * 1.07 : bobR,
        Paint()..color = bobColor..style = PaintingStyle.fill);

    // ── Bob shine ─────────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(bob.dx - bobR * 0.25, bob.dy - bobR * 0.25),
      bobR * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.35)..style = PaintingStyle.fill,
    );
  }


  @override
  bool shouldRepaint(covariant _GenericEffectPainter old) => true;
}
