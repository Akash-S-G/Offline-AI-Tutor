class RuleActionDefinition {
  final String id;
  final String label;
  final String description;
  final Map<String, String> configSchema;

  const RuleActionDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.configSchema,
  });
}

class RuleActionRegistry {
  static const List<RuleActionDefinition> definitions = [
    RuleActionDefinition(
      id: 'show_warning',
      label: 'Show Warning',
      description: 'Display a runtime warning message.',
      configSchema: {'message': 'string'},
    ),
    RuleActionDefinition(
      id: 'hide_object',
      label: 'Hide Object',
      description: 'Hide a runtime object.',
      configSchema: {'objectId': 'object'},
    ),
    RuleActionDefinition(
      id: 'show_object',
      label: 'Show Object',
      description: 'Show a runtime object.',
      configSchema: {'objectId': 'object'},
    ),
    RuleActionDefinition(
      id: 'set_variable',
      label: 'Set Variable',
      description: 'Set a runtime variable to a value.',
      configSchema: {'variableId': 'variable', 'value': 'dynamic'},
    ),
    RuleActionDefinition(
      id: 'toggle_variable',
      label: 'Toggle Variable',
      description: 'Toggle a boolean runtime variable.',
      configSchema: {'variableId': 'variable'},
    ),
  ];

  static const List<String> triggers = [
    'variableChanged',
    'thresholdCrossed',
    'buttonPressed',
    'toggleChanged',
    'intervalTriggered',
    'countdownFinished',
    'experimentStarted',
    'experimentPaused',
    'experimentCompleted',
  ];

  static RuleActionDefinition? byId(String id) {
    for (final definition in definitions) {
      if (definition.id == id) return definition;
    }
    return null;
  }
}
