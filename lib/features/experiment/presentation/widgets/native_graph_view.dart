import 'package:flutter/material.dart';
import '../../runtime/relationship_graph_model.dart';

class NativeGraphView extends StatelessWidget {
  final RelationshipGraphModel model;

  const NativeGraphView({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    // A simple placeholder for a native graph visualization
    // In a full implementation, this would use a CustomPainter or a package like graphview
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: model.nodes.length,
        itemBuilder: (context, index) {
          final node = model.nodes[index];
          final outgoingEdges = model.edges.where((e) => e.sourceId == node.id).toList();
          
          return Card(
            color: _getColorForType(node.type),
            child: ListTile(
              title: Text('${node.type.toUpperCase()}: ${node.label}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: outgoingEdges.map((e) => Text('--> [${e.type}] ${e.targetId}', style: const TextStyle(color: Colors.white70))).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'variable': return Colors.blue.shade700;
      case 'rule': return Colors.orange.shade700;
      case 'object': return Colors.green.shade700;
      default: return Colors.grey.shade700;
    }
  }
}
