class ManifestSanitizer {
  static const List<String> _allowedTopLevelKeys = [
    'scene', 'metadata', 'version'
  ];
  
  static const List<String> _allowedSceneKeys = [
    'sceneId', 'name', 'description', 'tags', 'variables', 'objects', 'rules'
  ];

  static const List<String> _allowedVariableKeys = [
    'id', 'name', 'type', 'value', 'description'
  ];

  static const List<String> _allowedObjectKeys = [
    'objectId', 'name', 'objectType', 'properties'
  ];

  static const List<String> _allowedRuleKeys = [
    'ruleId', 'name', 'condition', 'action', 'description'
  ];

  /// Returns a sanitized copy of the manifest, stripped of unknown keys.
  /// Throws FormatException if the fundamental structure is entirely malformed.
  static Map<String, dynamic> sanitize(Map<String, dynamic> rawManifest) {
    if (!rawManifest.containsKey('scene') || rawManifest['scene'] is! Map) {
      throw const FormatException('Manifest is missing required "scene" object.');
    }

    final sanitized = <String, dynamic>{};

    for (final key in _allowedTopLevelKeys) {
      if (rawManifest.containsKey(key)) {
        if (key == 'scene') {
          sanitized[key] = _sanitizeScene(rawManifest['scene'] as Map<String, dynamic>);
        } else {
          sanitized[key] = rawManifest[key];
        }
      }
    }

    return sanitized;
  }

  static Map<String, dynamic> _sanitizeScene(Map<String, dynamic> rawScene) {
    final sanitizedScene = <String, dynamic>{};

    for (final key in _allowedSceneKeys) {
      if (rawScene.containsKey(key)) {
        if (key == 'variables' && rawScene[key] is List) {
          sanitizedScene[key] = (rawScene[key] as List).map((v) {
            return _filterKeys(v as Map<String, dynamic>? ?? {}, _allowedVariableKeys);
          }).toList();
        } else if (key == 'objects' && rawScene[key] is List) {
          sanitizedScene[key] = (rawScene[key] as List).map((o) {
            return _filterKeys(o as Map<String, dynamic>? ?? {}, _allowedObjectKeys);
          }).toList();
        } else if (key == 'rules' && rawScene[key] is List) {
          sanitizedScene[key] = (rawScene[key] as List).map((r) {
            return _filterKeys(r as Map<String, dynamic>? ?? {}, _allowedRuleKeys);
          }).toList();
        } else {
          sanitizedScene[key] = rawScene[key];
        }
      }
    }

    return sanitizedScene;
  }

  static Map<String, dynamic> _filterKeys(Map<String, dynamic> input, List<String> allowedKeys) {
    final result = <String, dynamic>{};
    for (final key in allowedKeys) {
      if (input.containsKey(key)) {
        result[key] = input[key];
      }
    }
    return result;
  }
}
