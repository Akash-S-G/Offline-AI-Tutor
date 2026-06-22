import 'package:flutter/material.dart';
import '../../runtime/runtime_world.dart';
import 'measurement_tool.dart';

/// On-screen numeric readout that displays a specific variable.
/// Config requires:
/// - variable: The variable ID to read (e.g. "var_current")
/// - unit: The unit string to display (e.g. "A")
/// - label: Optional label (e.g. "Ammeter")
class NumericMeasurementTool implements MeasurementTool {
  @override
  String get type => 'numeric';

  @override
  Widget buildOverlay(RuntimeWorld world, BuildContext context, [Map<String, dynamic>? config]) {
    final variableId = config?['variable'] as String? ?? '';
    final unit = config?['unit'] as String? ?? '';
    final label = config?['label'] as String? ?? '';

    if (variableId.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 24,
      left: 24,
      child: _NumericWidget(
        world: world,
        variableId: variableId,
        unit: unit,
        label: label,
      ),
    );
  }
}

class _NumericWidget extends StatefulWidget {
  final RuntimeWorld world;
  final String variableId;
  final String unit;
  final String label;

  const _NumericWidget({
    required this.world,
    required this.variableId,
    required this.unit,
    required this.label,
  });

  @override
  State<_NumericWidget> createState() => _NumericWidgetState();
}

class _NumericWidgetState extends State<_NumericWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.world.variables,
      builder: (context, _) {
        final rawValue = widget.world.variables.getValue(widget.variableId);
        final val = (rawValue is num) ? rawValue.toDouble() : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withValues(alpha: 0.1),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      color: Colors.tealAccent.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    val.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      widget.unit,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
