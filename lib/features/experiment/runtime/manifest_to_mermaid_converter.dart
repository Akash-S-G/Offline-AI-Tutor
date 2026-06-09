class ManifestToMermaidConverter {
  static String convert(Map<String, dynamic> manifest) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('flowchart TD');
    
    final scene = manifest['scene'] as Map<String, dynamic>? ?? {};
    final variables = List<Map<String, dynamic>>.from(scene['variables'] ?? []);
    final rules = List<Map<String, dynamic>>.from(scene['rules'] ?? []);
    final objects = List<Map<String, dynamic>>.from(scene['objects'] ?? []);

    // Nodes
    for (var v in variables) {
      final name = v['name']?.toString().replaceAll(' ', '') ?? v['id'];
      buffer.writeln('  ${v['id']}("Variable: $name")');
    }
    for (var o in objects) {
      final name = o['name']?.toString().replaceAll(' ', '') ?? o['objectId'];
      buffer.writeln('  ${o['objectId']}("Object: $name")');
      
      // Link properties
      final props = o['properties'] as Map<String, dynamic>? ?? {};
      for (var entry in props.entries) {
        if (entry.value.toString().startsWith('var_')) {
          buffer.writeln('  ${entry.value} --> ${o['objectId']}');
        }
      }
    }

    for (var r in rules) {
      final name = r['name']?.toString().replaceAll(' ', '') ?? r['ruleId'];
      buffer.writeln('  ${r['ruleId']}{"Rule: $name"}');
      
      final condition = r['condition'];
      if (condition is Map && condition.containsKey('variableId')) {
        buffer.writeln('  ${condition['variableId']} --> ${r['ruleId']}');
      }

      final action = r['action'];
      if (action is String && action.contains('=')) {
        final target = action.split('=')[0].replaceAll('+', '').replaceAll('-', '').trim();
        // Assume target is a variable
        final targetVar = variables.firstWhere((v) => v['name'] == target || v['id'] == target, orElse: () => <String,dynamic>{});
        if (targetVar.isNotEmpty) {
          buffer.writeln('  ${r['ruleId']} --> ${targetVar['id']}');
        }
      }
    }

    return buffer.toString();
  }
}
