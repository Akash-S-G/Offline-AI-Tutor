import 'package:flutter/material.dart';

import '../domain/rule_action_registry.dart';
import '../models/builder_object.dart';
import '../models/builder_variable.dart';

typedef RuleConditionChanged = void Function(Map<String, dynamic> condition);
typedef RuleActionsChanged = void Function(List<Map<String, dynamic>> actions);
typedef RuleTriggerChanged = void Function(String trigger);

class RuleTriggerDropdown extends StatelessWidget {
  final String trigger;
  final RuleTriggerChanged onChanged;

  const RuleTriggerDropdown({
    super.key,
    required this.trigger,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = RuleActionRegistry.triggers.contains(trigger)
        ? trigger
        : 'variableChanged';
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: 'Rule Trigger',
        border: OutlineInputBorder(),
      ),
      items: RuleActionRegistry.triggers
          .map(
            (trigger) => DropdownMenuItem(value: trigger, child: Text(trigger)),
          )
          .toList(),
      onChanged: (value) => onChanged(value ?? selected),
    );
  }
}

class RuleTemplate {
  final String name;
  final Map<String, dynamic> condition;
  final List<Map<String, dynamic>> actions;

  const RuleTemplate({
    required this.name,
    required this.condition,
    required this.actions,
  });
}

class RuntimeRuleTemplates {
  static List<RuleTemplate> build({
    required List<BuilderVariable> variables,
    required List<BuilderObject> objects,
  }) {
    final numeric = variables.firstOrNull;
    final boolVar = variables.where((v) => v.defaultValue is bool).firstOrNull;
    final object = objects.firstOrNull;
    return [
      RuleTemplate(
        name: 'Temperature Warning',
        condition: {'variableId': numeric?.id, 'operator': '>=', 'value': 100},
        actions: const [
          {'type': 'show_warning', 'message': 'Water is boiling'},
        ],
      ),
      RuleTemplate(
        name: 'Visibility Toggle',
        condition: {
          'variableId': boolVar?.id ?? numeric?.id,
          'operator': '==',
          'value': false,
        },
        actions: [
          {'type': 'hide_object', 'objectId': object?.id},
        ],
      ),
      RuleTemplate(
        name: 'Variable Mutation',
        condition: {
          'variableId': boolVar?.id ?? numeric?.id,
          'operator': '==',
          'value': true,
        },
        actions: [
          {'type': 'set_variable', 'variableId': numeric?.id, 'value': 1},
        ],
      ),
    ];
  }
}

class ConditionBuilderEditor extends StatelessWidget {
  final List<BuilderVariable> variables;
  final Map<String, dynamic> condition;
  final RuleConditionChanged onChanged;

  const ConditionBuilderEditor({
    super.key,
    required this.variables,
    required this.condition,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final variableId = condition['variableId']?.toString();
    final operator = condition['operator']?.toString() ?? '==';
    final valueType = _valueType(condition['value']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Condition', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _VariableDropdown(
          label: 'Variable',
          variables: variables,
          value: variableId,
          onChanged: (value) => onChanged({...condition, 'variableId': value}),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: operator,
          decoration: const InputDecoration(
            labelText: 'Operator',
            border: OutlineInputBorder(),
          ),
          items: const [
            '==',
            '!=',
            '>',
            '>=',
            '<',
            '<=',
          ].map((op) => DropdownMenuItem(value: op, child: Text(op))).toList(),
          onChanged: (value) =>
              onChanged({...condition, 'operator': value ?? operator}),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: valueType,
          decoration: const InputDecoration(
            labelText: 'Value Type',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'number', child: Text('Number')),
            DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
            DropdownMenuItem(value: 'string', child: Text('String')),
          ],
          onChanged: (value) =>
              onChanged({...condition, 'value': _defaultValue(value)}),
        ),
        const SizedBox(height: 12),
        _ConditionValueField(
          valueType: valueType,
          value: condition['value'],
          onChanged: (value) => onChanged({...condition, 'value': value}),
        ),
      ],
    );
  }

  String _valueType(dynamic value) {
    if (value is bool) return 'boolean';
    if (value is num) return 'number';
    return 'string';
  }

  dynamic _defaultValue(String? type) {
    switch (type) {
      case 'boolean':
        return true;
      case 'string':
        return '';
      case 'number':
      default:
        return 0;
    }
  }
}

class ActionBuilderEditor extends StatelessWidget {
  final List<BuilderVariable> variables;
  final List<BuilderObject> objects;
  final List<Map<String, dynamic>> actions;
  final RuleActionsChanged onChanged;

  const ActionBuilderEditor({
    super.key,
    required this.variables,
    required this.objects,
    required this.actions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visibleActions = actions.isEmpty
        ? [
            {'type': 'show_warning', 'message': ''},
          ]
        : actions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...visibleActions.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SingleActionEditor(
              variables: variables,
              objects: objects,
              action: entry.value,
              onChanged: (action) {
                final next = [...visibleActions];
                next[entry.key] = action;
                onChanged(next);
              },
              onRemove: visibleActions.length == 1
                  ? null
                  : () {
                      final next = [...visibleActions]..removeAt(entry.key);
                      onChanged(next);
                    },
              onMoveUp: entry.key == 0
                  ? null
                  : () {
                      final next = [...visibleActions];
                      final action = next.removeAt(entry.key);
                      next.insert(entry.key - 1, action);
                      onChanged(next);
                    },
              onMoveDown: entry.key == visibleActions.length - 1
                  ? null
                  : () {
                      final next = [...visibleActions];
                      final action = next.removeAt(entry.key);
                      next.insert(entry.key + 1, action);
                      onChanged(next);
                    },
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => onChanged([
            ...visibleActions,
            {'type': 'show_warning', 'message': ''},
          ]),
          icon: const Icon(Icons.add),
          label: const Text('Add Action'),
        ),
      ],
    );
  }
}

class _SingleActionEditor extends StatelessWidget {
  final List<BuilderVariable> variables;
  final List<BuilderObject> objects;
  final Map<String, dynamic> action;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _SingleActionEditor({
    required this.variables,
    required this.objects,
    required this.action,
    required this.onChanged,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final type = action['type']?.toString() ?? 'show_warning';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    border: OutlineInputBorder(),
                  ),
                  items: RuleActionRegistry.definitions
                      .map(
                        (definition) => DropdownMenuItem(
                          value: definition.id,
                          child: Text(definition.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      onChanged(_defaultAction(value ?? type)),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
              if (onMoveUp != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Move up',
                  onPressed: onMoveUp,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
              if (onMoveDown != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: onMoveDown,
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ..._fieldsFor(type),
        ],
      ),
    );
  }

  List<Widget> _fieldsFor(String type) {
    switch (type) {
      case 'show_warning':
        return [
          _TextConfigField(
            label: 'Message',
            value: action['message']?.toString() ?? '',
            onChanged: (value) => onChanged({...action, 'message': value}),
          ),
        ];
      case 'hide_object':
      case 'show_object':
        return [
          _ObjectDropdown(
            label: 'Object',
            objects: objects,
            value: action['objectId']?.toString(),
            onChanged: (value) => onChanged({...action, 'objectId': value}),
          ),
        ];
      case 'set_variable':
        return [
          _VariableDropdown(
            label: 'Variable',
            variables: variables,
            value: action['variableId']?.toString(),
            onChanged: (value) => onChanged({...action, 'variableId': value}),
          ),
          const SizedBox(height: 12),
          _TextConfigField(
            label: 'Value',
            value: action['value']?.toString() ?? '',
            onChanged: (value) =>
                onChanged({...action, 'value': _parseValue(value)}),
          ),
        ];
      case 'toggle_variable':
        return [
          _VariableDropdown(
            label: 'Boolean Variable',
            variables: variables,
            value: action['variableId']?.toString(),
            onChanged: (value) => onChanged({...action, 'variableId': value}),
          ),
        ];
      default:
        return const [];
    }
  }

  Map<String, dynamic> _defaultAction(String type) {
    switch (type) {
      case 'hide_object':
      case 'show_object':
        return {'type': type, 'objectId': objects.firstOrNull?.id};
      case 'set_variable':
        return {
          'type': type,
          'variableId': variables.firstOrNull?.id,
          'value': 1,
        };
      case 'toggle_variable':
        return {'type': type, 'variableId': variables.firstOrNull?.id};
      case 'show_warning':
      default:
        return {'type': 'show_warning', 'message': ''};
    }
  }

  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    return num.tryParse(value) ?? value;
  }
}

class _ConditionValueField extends StatelessWidget {
  final String valueType;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _ConditionValueField({
    required this.valueType,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (valueType == 'boolean') {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Value'),
        value: value == true,
        onChanged: onChanged,
      );
    }
    return _TextConfigField(
      label: 'Value',
      value: value?.toString() ?? '',
      keyboardType: valueType == 'number'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: (text) {
        if (valueType == 'number') {
          onChanged(num.tryParse(text) ?? 0);
        } else {
          onChanged(text);
        }
      },
    );
  }
}

class _VariableDropdown extends StatelessWidget {
  final String label;
  final List<BuilderVariable> variables;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _VariableDropdown({
    required this.label,
    required this.variables,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = variables.any((variable) => variable.id == value)
        ? value
        : null;
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: variables
          .map(
            (variable) => DropdownMenuItem(
              value: variable.id,
              child: Text('${variable.name} (${variable.type})'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ObjectDropdown extends StatelessWidget {
  final String label;
  final List<BuilderObject> objects;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ObjectDropdown({
    required this.label,
    required this.objects,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = objects.any((object) => object.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: objects
          .map(
            (object) => DropdownMenuItem(
              value: object.id,
              child: Text('${object.name} (${object.type})'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TextConfigField extends StatefulWidget {
  final String label;
  final String value;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _TextConfigField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_TextConfigField> createState() => _TextConfigFieldState();
}

class _TextConfigFieldState extends State<_TextConfigField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TextConfigField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}
