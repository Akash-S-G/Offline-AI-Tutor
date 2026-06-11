import 'package:flutter/material.dart';

import '../../runtime/models/runtime_object_state.dart';
import '../../runtime/object_registry.dart';
import '../../runtime/runtime_event.dart';
import 'runtime_workspace_layout_manager.dart';
import 'widgets/experiment_canvas.dart';
import 'widgets/runtime_hud.dart';

class RuntimeWorkspace extends StatefulWidget {
  final ObjectRegistry objectRegistry;
  final Widget simulationCanvas;
  final List<RuntimeEvent> warnings;
  final ValueChanged<String>? onFeedback;

  const RuntimeWorkspace({
    super.key,
    required this.objectRegistry,
    required this.simulationCanvas,
    this.warnings = const [],
    this.onFeedback,
  });

  @override
  State<RuntimeWorkspace> createState() => _RuntimeWorkspaceState();
}

class _RuntimeWorkspaceState extends State<RuntimeWorkspace> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.objectRegistry,
      builder: (context, _) {
        final layout = RuntimeExperienceLayoutManager().build(
          widget.objectRegistry.allObjectStates,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            ExperimentCanvas(child: widget.simulationCanvas),
            RuntimeHud(displays: layout.displayObjects),
            _WarningStack(warnings: widget.warnings),
            _FloatingControlTray(
              controls: layout.controlObjects,
              registry: widget.objectRegistry,
              onFeedback: widget.onFeedback,
              onOpenGraphs: layout.analysisObjects.isEmpty
                  ? null
                  : () => _openObjectPanel(
                      title: 'Graphs',
                      objects: layout.analysisObjects,
                    ),
              onOpenData: layout.dataObjects.isEmpty
                  ? null
                  : () => _openObjectPanel(
                      title: 'Data',
                      objects: layout.dataObjects,
                    ),
            ),
          ],
        );
      },
    );
  }

  void _openObjectPanel({
    required String title,
    required List<RuntimeObjectState> objects,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.62,
          child: _ObjectOverlayPanel(title: title, objects: objects),
        );
      },
    );
  }
}

class _FloatingControlTray extends StatelessWidget {
  final List<RuntimeObjectState> controls;
  final ObjectRegistry registry;
  final ValueChanged<String>? onFeedback;
  final VoidCallback? onOpenGraphs;
  final VoidCallback? onOpenData;

  const _FloatingControlTray({
    required this.controls,
    required this.registry,
    this.onFeedback,
    this.onOpenGraphs,
    this.onOpenData,
  });

  @override
  Widget build(BuildContext context) {
    if (controls.isEmpty && onOpenGraphs == null && onOpenData == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 68),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  ...controls.map((state) {
                    if (state.objectType == 'slider') {
                      return _CompactSlider(
                        state: state,
                        registry: registry,
                        onFeedback: onFeedback,
                      );
                    }
                    if (state.objectType == 'toggle') {
                      return _CompactToggle(
                        state: state,
                        registry: registry,
                        onFeedback: onFeedback,
                      );
                    }
                    return _TrayButton(
                      icon: Icons.touch_app,
                      label: _labelFor(state),
                      onPressed: () =>
                          onFeedback?.call('${_labelFor(state)} pressed'),
                    );
                  }),
                  if (onOpenGraphs != null)
                    _TrayButton(
                      icon: Icons.show_chart,
                      label: 'Graphs',
                      onPressed: onOpenGraphs,
                    ),
                  if (onOpenData != null)
                    _TrayButton(
                      icon: Icons.table_chart,
                      label: 'Data',
                      onPressed: onOpenData,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSlider extends StatelessWidget {
  final RuntimeObjectState state;
  final ObjectRegistry registry;
  final ValueChanged<String>? onFeedback;

  const _CompactSlider({
    required this.state,
    required this.registry,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final min = _readDouble(state.state['min'], 0);
    final max = _readDouble(state.state['max'], 100);
    final value = _readDouble(state.state['value'], min).clamp(min, max);
    return SizedBox(
      width: 240,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              _labelFor(state),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: min,
              max: max <= min ? min + 1 : max,
              onChanged: (next) {
                registry.updateObjectState(state.objectId, 'value', next);
                onFeedback?.call(
                  '${_labelFor(state)} = ${next.toStringAsFixed(1)}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactToggle extends StatelessWidget {
  final RuntimeObjectState state;
  final ObjectRegistry registry;
  final ValueChanged<String>? onFeedback;

  const _CompactToggle({
    required this.state,
    required this.registry,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final value = state.state['value'] == true;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_labelFor(state), style: const TextStyle(color: Colors.white)),
        Switch(
          value: value,
          onChanged: (next) {
            registry.updateObjectState(state.objectId, 'value', next);
            onFeedback?.call('${_labelFor(state)} ${next ? 'On' : 'Off'}');
          },
        ),
      ],
    );
  }
}

class _TrayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _TrayButton({required this.icon, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton.filledTonal(
        onPressed: onPressed,
        tooltip: label,
        icon: Icon(icon),
      ),
    );
  }
}

class _WarningStack extends StatelessWidget {
  final List<RuntimeEvent> warnings;

  const _WarningStack({required this.warnings});

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: warnings.take(3).map((warning) {
          return Container(
            width: 260,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade700.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warning.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ObjectOverlayPanel extends StatelessWidget {
  final String title;
  final List<RuntimeObjectState> objects;

  const _ObjectOverlayPanel({required this.title, required this.objects});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisExtent: 150,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: objects.length,
              itemBuilder: (context, index) {
                return _RuntimeObjectCard(state: objects[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RuntimeObjectCard extends StatelessWidget {
  final RuntimeObjectState state;

  const _RuntimeObjectCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _labelFor(state),
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              _valueFor(state),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _readableType(state.objectType),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

String _labelFor(RuntimeObjectState state) {
  return state.state['label']?.toString().isNotEmpty == true
      ? state.state['label'].toString()
      : _readableType(state.objectType);
}

String _valueFor(RuntimeObjectState state) {
  final unit = state.state['unit']?.toString() ?? '';
  final explicit =
      state.state['formattedValue'] ??
      state.state['formattedText'] ??
      state.state['text'];
  if (explicit != null && explicit.toString().isNotEmpty) {
    return unit.isEmpty ? explicit.toString() : '$explicit $unit';
  }
  final value =
      state.state['value'] ??
      state.state['progress'] ??
      state.state['normalizedValue'] ??
      state.state['magnitude'] ??
      state.state['sampleCount'] ??
      state.state['pointCount'];
  if (value == null) return _readableType(state.objectType);
  if (value is num) {
    final precision = _readInt(state.state['precision'], 1);
    final text = value.toDouble().toStringAsFixed(precision);
    return unit.isEmpty ? text : '$text $unit';
  }
  return unit.isEmpty ? value.toString() : '$value $unit';
}

String _readableType(String type) {
  final spaced = type.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

double _readDouble(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int _readInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
