import 'package:flutter/material.dart';

import '../../runtime/models/runtime_object_state.dart';
import '../../runtime/object_registry.dart';
import '../services/runtime_label_formatter.dart';

class GraphWorkspace extends StatelessWidget {
  final ObjectRegistry objectRegistry;
  final RuntimeLabelFormatter formatter;

  const GraphWorkspace({
    super.key,
    required this.objectRegistry,
    this.formatter = const RuntimeLabelFormatter(),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: objectRegistry,
      builder: (context, _) {
        final graphs = objectRegistry.allObjectStates
            .where((state) => state.visible)
            .where(
              (state) => {
                'lineGraph',
                'scatterPlot',
                'barChart',
                'oscilloscope',
                'spectrumAnalyzer',
                'vectorVisualizer',
              }.contains(state.objectType),
            )
            .toList(growable: false);
        if (graphs.isEmpty) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.show_chart, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Graphs: ${graphs.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showGraphs(context, graphs),
                  icon: const Icon(Icons.open_in_full),
                  label: const Text('Show'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGraphs(BuildContext context, List<RuntimeObjectState> graphs) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final graph = graphs[index];
              return ListTile(
                leading: const Icon(Icons.show_chart),
                title: Text(formatter.format(graph.objectId)),
                subtitle: Text(formatter.format(graph.objectType)),
              );
            },
            separatorBuilder: (_, _) => const Divider(),
            itemCount: graphs.length,
          ),
        );
      },
    );
  }
}
