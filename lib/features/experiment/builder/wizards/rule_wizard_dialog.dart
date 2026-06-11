import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/rule_registry.dart';
import '../models/builder_object.dart';
import '../models/builder_rule.dart';
import '../models/builder_variable.dart';
import '../widgets/rule_runtime_config_editors.dart';

class RuleWizardDialog extends StatefulWidget {
  final List<BuilderVariable> availableVariables;
  final List<BuilderObject> availableObjects;

  const RuleWizardDialog({
    super.key,
    required this.availableVariables,
    required this.availableObjects,
  });

  @override
  State<RuleWizardDialog> createState() => _RuleWizardDialogState();
}

class _RuleWizardDialogState extends State<RuleWizardDialog> {
  int _currentStep = 0;
  RuleDefinition? _selectedType;

  final _nameController = TextEditingController();
  String _trigger = 'variableChanged';
  Map<String, dynamic> _condition = const {};
  List<Map<String, dynamic>> _actions = const [
    {'type': 'show_warning', 'message': ''},
  ];

  bool get _canProceed {
    if (_currentStep == 0) return _selectedType != null;
    if (_currentStep == 1) return _nameController.text.trim().isNotEmpty;
    if (_currentStep == 2) {
      return _condition['variableId']?.toString().isNotEmpty == true &&
          _actions.isNotEmpty;
    }
    return false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createRule() {
    if (!_canProceed) return;

    final condition = Map<String, dynamic>.from(_condition);
    final newRule = BuilderRule(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      condition: condition,
      actions: _actions,
      trigger: _trigger,
      description: _selectedType!.description,
      runtimeConfig: {
        'trigger': _trigger,
        'condition': condition,
        'actions': _actions,
      },
    );

    Navigator.of(context).pop(newRule);
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: RuleRegistry.definitions.map((def) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(def.icon),
            title: Text(def.title),
            subtitle: Text(def.description),
            selected: _selectedType == def,
            selectedTileColor: Colors.blue.withValues(alpha: 0.1),
            onTap: () {
              setState(() {
                _selectedType = def;
                _nameController.text = '${def.title.replaceAll(' ', '')}Rule';
                _applyDefaultTemplate();
              });
            },
          ),
        );
      }).toList(),
    );
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return 'Choose Logic Type';
      case 1:
        return 'Name Rule';
      default:
        return 'Configure Logic';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildTypeSelection();
      case 1:
        return _buildBasicConfig();
      default:
        return _buildLogicConfig();
    }
  }

  Widget _buildStepHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_stepTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_currentStep + 1) / 3),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of 3',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicConfig() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Rule Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildLogicConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _templatePicker(),
        const SizedBox(height: 16),
        RuleTriggerDropdown(
          trigger: _trigger,
          onChanged: (trigger) => setState(() => _trigger = trigger),
        ),
        const SizedBox(height: 16),
        ConditionBuilderEditor(
          variables: widget.availableVariables,
          condition: _condition,
          onChanged: (condition) => setState(() => _condition = condition),
        ),
        const SizedBox(height: 16),
        ActionBuilderEditor(
          variables: widget.availableVariables,
          objects: widget.availableObjects,
          actions: _actions,
          onChanged: (actions) => setState(() => _actions = actions),
        ),
      ],
    );
  }

  Widget _templatePicker() {
    final templates = RuntimeRuleTemplates.build(
      variables: widget.availableVariables,
      objects: widget.availableObjects,
    );
    return DropdownButtonFormField<RuleTemplate>(
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Starter Template',
        border: OutlineInputBorder(),
      ),
      items: templates
          .map(
            (template) =>
                DropdownMenuItem(value: template, child: Text(template.name)),
          )
          .toList(),
      onChanged: (template) {
        if (template == null) return;
        setState(() {
          _nameController.text = template.name;
          _trigger = 'thresholdCrossed';
          _condition = Map<String, dynamic>.from(template.condition);
          _actions = template.actions
              .map((action) => Map<String, dynamic>.from(action))
              .toList();
        });
      },
    );
  }

  void _applyDefaultTemplate() {
    final template = RuntimeRuleTemplates.build(
      variables: widget.availableVariables,
      objects: widget.availableObjects,
    ).firstOrNull;
    _condition = Map<String, dynamic>.from(
      template?.condition ??
          {
            'variableId': widget.availableVariables.firstOrNull?.id,
            'operator': '>=',
            'value': 100,
          },
    );
    _trigger = 'variableChanged';
    _actions =
        template?.actions
            .map((action) => Map<String, dynamic>.from(action))
            .toList() ??
        [
          {'type': 'show_warning', 'message': ''},
        ];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Logic Rule'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildStepHeader(),
              Expanded(
                child: SingleChildScrollView(
                  key: const PageStorageKey<String>('rule_wizard_step_scroll'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: _buildCurrentStep(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (_currentStep > 0) {
                            setState(() => _currentStep -= 1);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canProceed
                            ? () {
                                if (_currentStep < 2) {
                                  setState(() => _currentStep += 1);
                                } else {
                                  _createRule();
                                }
                              }
                            : null,
                        child: Text(_currentStep == 2 ? 'Create' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
