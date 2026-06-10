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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: RuleRegistry.definitions.length,
      itemBuilder: (context, index) {
        final def = RuleRegistry.definitions[index];
        return ListTile(
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
        );
      },
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Stepper(
                    currentStep: _currentStep,
                    controlsBuilder: (context, details) =>
                        const SizedBox.shrink(),
                    steps: [
                      Step(
                        title: const Text('Rule Type'),
                        content: _buildTypeSelection(),
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0
                            ? StepState.complete
                            : StepState.indexed,
                      ),
                      Step(
                        title: const Text('Identity'),
                        content: _buildBasicConfig(),
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1
                            ? StepState.complete
                            : StepState.indexed,
                      ),
                      Step(
                        title: const Text('Logic'),
                        content: _buildLogicConfig(),
                        isActive: _currentStep >= 2,
                      ),
                    ],
                  ),
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
