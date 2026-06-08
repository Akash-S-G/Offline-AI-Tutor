import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/object_registry.dart';
import '../models/builder_object.dart';
import '../models/builder_variable.dart';
import '../domain/variable_registry.dart';

class ObjectWizardDialog extends StatefulWidget {
  final List<BuilderVariable> availableVariables;
  
  const ObjectWizardDialog({super.key, required this.availableVariables});

  @override
  State<ObjectWizardDialog> createState() => _ObjectWizardDialogState();
}

class _ObjectWizardDialogState extends State<ObjectWizardDialog> {
  int _currentStep = 0;
  ObjectDefinition? _selectedType;
  
  final _nameController = TextEditingController();
  BuilderVariable? _linkedVariable;

  bool get _canProceed {
    if (_currentStep == 0) return _selectedType != null;
    if (_currentStep == 1) return _nameController.text.trim().isNotEmpty && _linkedVariable != null;
    return false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createObject() {
    if (!_canProceed) return;

    final newObj = BuilderObject(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _selectedType!.type.name,
      properties: {
        'linked_variable': _linkedVariable!.id,
      },
    );

    Navigator.of(context).pop(newObj);
  }

  Widget _buildTypeSelection() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: ObjectRegistry.definitions.length,
      itemBuilder: (context, index) {
        final def = ObjectRegistry.definitions[index];
        return ListTile(
          leading: Icon(def.icon),
          title: Text(def.title),
          subtitle: Text(def.description),
          selected: _selectedType == def,
          selectedTileColor: Colors.blue.withOpacity(0.1),
          onTap: () {
            setState(() {
              _selectedType = def;
              _nameController.text = def.title.toLowerCase().replaceAll(' ', '_');
              // Auto-select first compatible variable if available
              _linkedVariable = _getCompatibleVariables(def).firstOrNull;
            });
          },
        );
      },
    );
  }

  List<BuilderVariable> _getCompatibleVariables(ObjectDefinition def) {
    return widget.availableVariables.where((v) {
      // Very basic loose matching since VariableRegistry types mapped strings.
      // A more robust implementation would use full VariableType.
      return true; // Simplify for now, ideally filter by category.
    }).toList();
  }

  Widget _buildConfiguration() {
    final compatibleVars = _selectedType != null ? _getCompatibleVariables(_selectedType!) : <BuilderVariable>[];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedType != null) ...[
          Row(
            children: [
              Icon(_selectedType!.icon, size: 32, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Configure ${_selectedType!.title}', 
                  style: Theme.of(context).textTheme.titleLarge,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Object Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<BuilderVariable>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Linked Variable',
            border: OutlineInputBorder(),
          ),
          value: _linkedVariable,
          items: compatibleVars.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text('${v.name} (${v.type})'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _linkedVariable = val;
            });
          },
        ),
        if (compatibleVars.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('No compatible variables found. Please create a variable first.', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Object'),
      content: SizedBox(
        width: double.maxFinite,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 1) {
              if (_canProceed) setState(() => _currentStep += 1);
            } else {
              _createObject();
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
                    child: Text(_currentStep == 1 ? 'Create' : 'Next'),
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
              title: const Text('Visualization Type'),
              content: _buildTypeSelection(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Configure'),
              content: _buildConfiguration(),
              isActive: _currentStep >= 1,
            ),
          ],
        ),
      ),
    );
  }
}
