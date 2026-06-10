class RuntimeMultiBinding {
  final String objectId;
  final String objectType;
  final Map<String, String> variableIdsByRole;

  const RuntimeMultiBinding({
    required this.objectId,
    required this.objectType,
    required this.variableIdsByRole,
  });

  factory RuntimeMultiBinding.fromObjectJson(Map<String, dynamic> objectJson) {
    final objectId =
        objectJson['objectId']?.toString() ??
        objectJson['id']?.toString() ??
        '';
    final objectType =
        objectJson['objectType']?.toString() ??
        objectJson['type']?.toString() ??
        '';
    final properties = Map<String, dynamic>.from(
      objectJson['properties'] as Map? ?? const {},
    );
    final config = Map<String, dynamic>.from(
      objectJson['runtimeConfig'] as Map? ??
          properties['runtimeConfig'] as Map? ??
          const {},
    );
    final merged = {...properties, ...config, ...objectJson};
    final bindings = <String, String>{};

    void add(String role, List<String> keys) {
      for (final key in keys) {
        final value = merged[key];
        if (value != null && value.toString().isNotEmpty) {
          bindings[role] = value.toString();
          return;
        }
      }
    }

    add('value', const [
      'variableId',
      'linkedVariable',
      'linked_variable',
      'valueVariable',
      'sourceVariable',
    ]);
    add('x', const ['xVariable', 'x_variable', 'xVariableId']);
    add('y', const ['yVariable', 'y_variable', 'yVariableId']);
    add('z', const ['zVariable', 'z_variable', 'zVariableId']);
    add('source', const ['sourceVariable', 'source_variable']);

    final variableIds = merged['variableIds'] ?? merged['variables'];
    if (variableIds is List) {
      for (var i = 0; i < variableIds.length; i++) {
        final id = variableIds[i]?.toString();
        if (id != null && id.isNotEmpty) bindings['bar_$i'] = id;
      }
    }
    final bars = merged['bars'];
    if (bars is List) {
      for (var i = 0; i < bars.length; i++) {
        final bar = bars[i];
        if (bar is Map) {
          final id = bar['variableId']?.toString();
          if (id != null && id.isNotEmpty) bindings['bar_$i'] = id;
        }
      }
    }

    return RuntimeMultiBinding(
      objectId: objectId,
      objectType: objectType,
      variableIdsByRole: bindings,
    );
  }

  String? variableForRole(String role) => variableIdsByRole[role];

  List<String> variablesForPrefix(String prefix) {
    return variableIdsByRole.entries
        .where((entry) => entry.key.startsWith(prefix))
        .map((entry) => entry.value)
        .toList(growable: false);
  }
}
