class RuntimeValidationException implements Exception {
  final String message;
  RuntimeValidationException(this.message);
  @override
  String toString() => 'RuntimeValidationException: $message';
}

class RuntimeValidator {
  static void validate(Map<String, dynamic> manifest) {
    if (!manifest.containsKey('scene')) {
      throw RuntimeValidationException("Manifest must contain a 'scene' object.");
    }
    
    final scene = manifest['scene'] as Map<String, dynamic>;
    final variables = List<Map<String, dynamic>>.from(scene['variables'] ?? []);
    final objects = List<Map<String, dynamic>>.from(scene['objects'] ?? []);
    final rules = List<Map<String, dynamic>>.from(scene['rules'] ?? []);

    final varIds = variables.map((v) => (v['id'] ?? v['name']).toString()).toSet();

    // Validate Objects
    for (var obj in objects) {
      if (!obj.containsKey('objectId') && !obj.containsKey('id')) {
        throw RuntimeValidationException("All objects must have an 'objectId'.");
      }
      final props = obj['properties'] as Map<String, dynamic>? ?? {};
      for (var entry in props.entries) {
        if (entry.value is String && entry.value.toString().startsWith('var_')) {
          if (!varIds.contains(entry.value)) {
            throw RuntimeValidationException("Object references undefined variable: ${entry.value}");
          }
        }
      }
    }

    // Build Dependency Graph
    final Map<String, List<String>> graph = {};
    
    // Validate Rules & build graph edges
    for (var rule in rules) {
      if (!rule.containsKey('ruleId')) {
        throw RuntimeValidationException("All rules must have a 'ruleId'.");
      }
      final ruleId = rule['ruleId'].toString();
      graph[ruleId] = [];

      final condition = rule['condition'];
      if (condition is Map && condition.containsKey('variableId')) {
        final varId = condition['variableId'].toString();
        if (!varIds.contains(varId)) {
          throw RuntimeValidationException("Rule condition references undefined variable: $varId");
        }
        // Variable triggers Rule (Edge: Var -> Rule)
        graph.putIfAbsent(varId, () => []).add(ruleId);
      }

      final action = rule['action'];
      if (action is String && action.contains('=')) {
        final target = action.split('=')[0].replaceAll('+', '').replaceAll('-', '').trim();
        // Assume target is a variable
        final targetVar = variables.firstWhere((v) => v['name'] == target || v['id'] == target, orElse: () => <String,dynamic>{});
        if (targetVar.isNotEmpty) {
           // Rule updates Variable (Edge: Rule -> Var)
           graph[ruleId]!.add(targetVar['id'].toString());
        }
      }
    }

    _detectCycles(graph);
  }

  static void _detectCycles(Map<String, List<String>> graph) {
    final Set<String> visited = {};
    final Set<String> recursionStack = {};

    bool dfs(String node) {
      visited.add(node);
      recursionStack.add(node);

      if (graph.containsKey(node)) {
        for (var neighbor in graph[node]!) {
          if (!visited.contains(neighbor) && dfs(neighbor)) {
            return true;
          } else if (recursionStack.contains(neighbor)) {
            return true;
          }
        }
      }

      recursionStack.remove(node);
      return false;
    }

    for (var node in graph.keys) {
      if (!visited.contains(node)) {
        if (dfs(node)) {
          throw RuntimeValidationException("Circular dependency detected involving: $node");
        }
      }
    }
  }
}
