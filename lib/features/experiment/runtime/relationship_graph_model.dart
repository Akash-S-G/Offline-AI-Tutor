class GraphNode {
  final String id;
  final String label;
  final String type; // variable, object, rule
  
  GraphNode({required this.id, required this.label, required this.type});
}

class GraphEdge {
  final String sourceId;
  final String targetId;
  final String type; // triggers, updates, links

  GraphEdge({required this.sourceId, required this.targetId, required this.type});
}

class RelationshipGraphModel {
  final List<GraphNode> nodes = [];
  final List<GraphEdge> edges = [];

  static RelationshipGraphModel fromManifest(Map<String, dynamic> manifest) {
    final model = RelationshipGraphModel();
    final scene = manifest['scene'] as Map<String, dynamic>? ?? {};
    final variables = List<Map<String, dynamic>>.from(scene['variables'] ?? []);
    final objects = List<Map<String, dynamic>>.from(scene['objects'] ?? []);
    final rules = List<Map<String, dynamic>>.from(scene['rules'] ?? []);

    for (var v in variables) {
      final id = v['id'] ?? v['name'];
      model.nodes.add(GraphNode(id: id, label: v['name'] ?? id, type: 'variable'));
    }

    for (var o in objects) {
      final id = o['objectId'] ?? o['id'];
      model.nodes.add(GraphNode(id: id, label: o['name'] ?? id, type: 'object'));
      
      final props = o['properties'] as Map<String, dynamic>? ?? {};
      for (var entry in props.entries) {
        if (entry.value.toString().startsWith('var_')) {
          model.edges.add(GraphEdge(sourceId: entry.value, targetId: id, type: 'links'));
        }
      }
    }

    for (var r in rules) {
      final id = r['ruleId'];
      model.nodes.add(GraphNode(id: id, label: r['name'] ?? id, type: 'rule'));
      
      final condition = r['condition'];
      if (condition is Map && condition.containsKey('variableId')) {
        model.edges.add(GraphEdge(sourceId: condition['variableId'], targetId: id, type: 'triggers'));
      }

      final action = r['action'];
      if (action is String && action.contains('=')) {
        final target = action.split('=')[0].replaceAll('+', '').replaceAll('-', '').trim();
        final targetVar = variables.firstWhere((v) => v['name'] == target || v['id'] == target, orElse: () => <String,dynamic>{});
        if (targetVar.isNotEmpty) {
          model.edges.add(GraphEdge(sourceId: id, targetId: targetVar['id'], type: 'updates'));
        }
      }
    }

    return model;
  }

  String toMermaid() {
    final buffer = StringBuffer();
    buffer.writeln('flowchart TD');
    
    for (var node in nodes) {
      final safeLabel = node.label.replaceAll('"', '');
      if (node.type == 'variable') buffer.writeln('  ${node.id}(("$safeLabel"))');
      else if (node.type == 'object') buffer.writeln('  ${node.id}["$safeLabel"]');
      else if (node.type == 'rule') buffer.writeln('  ${node.id}{"$safeLabel"}');
    }

    for (var edge in edges) {
      if (edge.type == 'updates') {
        buffer.writeln('  ${edge.sourceId} ==>|updates| ${edge.targetId}');
      } else if (edge.type == 'triggers') {
        buffer.writeln('  ${edge.sourceId} -.->|triggers| ${edge.targetId}');
      } else {
        buffer.writeln('  ${edge.sourceId} --- ${edge.targetId}');
      }
    }

    return buffer.toString();
  }
}
