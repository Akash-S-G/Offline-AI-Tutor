import 'package:flutter/material.dart';

enum RuleType {
  threshold,
  comparison,
  timer,
  sensorEvent,
  buttonEvent,
  calculation,
  visibility,
  dataCollection,
}

class RuleDefinition {
  final RuleType type;
  final String title;
  final String description;
  final IconData icon;
  final List<String> requiredFields;

  const RuleDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredFields,
  });
}

class RuleRegistry {
  static const List<RuleDefinition> definitions = [
    RuleDefinition(
      type: RuleType.threshold,
      title: 'Threshold',
      description: 'Trigger when a variable crosses a value',
      icon: Icons.horizontal_rule,
      requiredFields: ['variable', 'operator', 'value', 'action'],
    ),
    RuleDefinition(
      type: RuleType.comparison,
      title: 'Comparison',
      description: 'Compare two variables',
      icon: Icons.compare_arrows,
      requiredFields: ['variable1', 'operator', 'variable2', 'action'],
    ),
    RuleDefinition(
      type: RuleType.timer,
      title: 'Timer',
      description: 'Trigger an action after elapsed time',
      icon: Icons.timer,
      requiredFields: ['time_seconds', 'action'],
    ),
    RuleDefinition(
      type: RuleType.sensorEvent,
      title: 'Sensor Event',
      description: 'Trigger on specific sensor patterns (e.g. Shake)',
      icon: Icons.sensors,
      requiredFields: ['sensor', 'pattern', 'action'],
    ),
    RuleDefinition(
      type: RuleType.buttonEvent,
      title: 'Button Event',
      description: 'Trigger when a UI button is pressed',
      icon: Icons.touch_app,
      requiredFields: ['button_id', 'action'],
    ),
    RuleDefinition(
      type: RuleType.calculation,
      title: 'Calculation',
      description: 'Update a computed variable constantly',
      icon: Icons.calculate,
      requiredFields: ['output_variable', 'formula'],
    ),
    RuleDefinition(
      type: RuleType.visibility,
      title: 'Visibility Control',
      description: 'Show or hide objects based on conditions',
      icon: Icons.visibility,
      requiredFields: ['condition', 'object_id', 'visibility_state'],
    ),
    RuleDefinition(
      type: RuleType.dataCollection,
      title: 'Data Collection',
      description: 'Start or stop recording data',
      icon: Icons.dataset,
      requiredFields: ['trigger_condition', 'variables_to_record'],
    ),
  ];
}
