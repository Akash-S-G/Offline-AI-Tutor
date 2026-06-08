import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/rule_registry.dart';
import '../models/builder_rule.dart';
import '../models/builder_variable.dart';

class RuleWizardDialog extends StatefulWidget {
  final List<BuilderVariable> availableVariables;

  const RuleWizardDialog({super.key, required this.availableVariables});

  @override
  State<RuleWizardDialog> createState() => _RuleWizardDialogState();
}

class _RuleWizardDialogState extends State<RuleWizardDialog> {
  int _currentStep = 0;
  RuleDefinition? _selectedType;
  
  final _nameController = TextEditingController();
  
  // Threshold Rule State
  BuilderVariable? _selectedVariable;
  String _selectedOperator = '>';
  final _thresholdValueController = TextEditingController();
  String _selectedAction = 'show_warning';

  bool get _canProceed {
    if (_currentStep == 0) return _selectedType != null;
    if (_currentStep == 1) return _nameController.text.trim().isNotEmpty;
    if (_currentStep == 2) {
      if (_selectedType?.type == RuleType.threshold) {
        return _selectedVariable != null && _thresholdValueController.text.isNotEmpty;
      }
      return true; // Other types bypass deep validation for MVP
    }
    return false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thresholdValueController.dispose();
    super.dispose();
  }

  void _createRule() {
    if (!_canProceed) return;

    Map<String, dynamic> condition = {};
    Map<String, dynamic> action = {};

    if (_selectedType!.type == RuleType.threshold) {
      condition = {
        'variableId': _selectedVariable!.id,
        'operator': _selectedOperator,
        'value': num.tryParse(_thresholdValueController.text) ?? 0,
      };
      action = {
        'type': _selectedAction,
      };
    } else {
      // Stub condition/action for other types
      condition = {'type': 'generic_condition'};
      action = {'type': 'generic_action'};
    }

    final newRule = BuilderRule(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      condition: condition,
      action: action,
      description: _selectedType!.description,
    );

    Navigator.of(context).pop(newRule);
  }

  Widget _buildTypeSelection() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: RuleRegistry.definitions.length,
      itemBuilder: (context, index) {
        final def = RuleRegistry.definitions[index];
        return ListTile(
          leading: Icon(def.icon),
          title: Text(def.title),
          subtitle: Text(def.description),
          selected: _selectedType == def,
          selectedTileColor: Colors.blue.withOpacity(0.1),
          onTap: () {
            setState(() {
              _selectedType = def;
              _nameController.text = '${def.title.replaceAll(' ', '')}Rule';
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
    if (_selectedType?.type == RuleType.threshold) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('IF', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          DropdownButtonFormField<BuilderVariable>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Variable', border: OutlineInputBorder()),
            value: _selectedVariable,
            items: widget.availableVariables.map((v) {
              return DropdownMenuItem(value: v, child: Text(v.name));
            }).toList(),
            onChanged: (val) => setState(() => _selectedVariable = val),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Operator', border: OutlineInputBorder()),
            value: _selectedOperator,
            items: const [
              DropdownMenuItem(value: '>', child: Text('Greater Than (>)?')),
              DropdownMenuItem(value: '<', child: Text('Less Than (<)?')),
              DropdownMenuItem(value: '>=', child: Text('Greater or Equal (>=)?')),
              DropdownMenuItem(value: '<=', child: Text('Less or Equal (<=)?')),
              DropdownMenuItem(value: '==', child: Text('Equals (==)?')),
            ],
            onChanged: (val) => setState(() => _selectedOperator = val!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _thresholdValueController,
            decoration: const InputDecoration(labelText: 'Threshold Value', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          const Text('THEN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Action', border: OutlineInputBorder()),
            value: _selectedAction,
            items: const [
              DropdownMenuItem(value: 'show_warning', child: Text('Show Warning')),
              DropdownMenuItem(value: 'hide_object', child: Text('Hide Object')),
              DropdownMenuItem(value: 'start_recording', child: Text('Start Recording')),
              DropdownMenuItem(value: 'stop_recording', child: Text('Stop Recording')),
            ],
            onChanged: (val) => setState(() => _selectedAction = val!),
          ),
        ],
      );
    }
    
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('Logic builder for this rule type is under construction. It will be added with default generic logic for now.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Logic Rule'),
      content: SizedBox(
        width: double.maxFinite,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              if (_canProceed) setState(() => _currentStep += 1);
            } else {
              _createRule();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              Navigator.of(context).pop();
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _canProceed ? details.onStepContinue : null,
                    child: Text(_currentStep == 2 ? 'Create' : 'Next'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Rule Type'),
              content: _buildTypeSelection(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Identity'),
              content: _buildBasicConfig(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Logic'),
              content: _buildLogicConfig(),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }
}
