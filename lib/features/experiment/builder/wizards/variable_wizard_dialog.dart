import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/variable_registry.dart';
import '../models/builder_variable.dart';

class VariableWizardDialog extends StatefulWidget {
  const VariableWizardDialog({super.key});

  @override
  State<VariableWizardDialog> createState() => _VariableWizardDialogState();
}

class _VariableWizardDialogState extends State<VariableWizardDialog> {
  int _currentStep = 0;
  VariableCategory? _selectedCategory;
  VariableDefinition? _selectedType;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  bool get _canProceed {
    if (_currentStep == 0) return _selectedCategory != null;
    if (_currentStep == 1) return _selectedType != null;
    if (_currentStep == 2) return _nameController.text.trim().isNotEmpty;
    return false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _createVariable() {
    if (!_canProceed) return;

    final newVar = BuilderVariable(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _selectedType!.type.name,
      defaultValue: _selectedType!.defaultValue,
      description: _descController.text.trim(),
    );

    Navigator.of(context).pop(newVar);
  }

  Widget _buildCategorySelection() {
    return ListView(
      shrinkWrap: true,
      children: VariableCategory.values.map((category) {
        return RadioListTile<VariableCategory>(
          title: Text(category.name.toUpperCase()),
          value: category,
          groupValue: _selectedCategory,
          onChanged: (val) {
            setState(() {
              _selectedCategory = val;
              _selectedType = null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTypeSelection() {
    if (_selectedCategory == null) return const SizedBox.shrink();
    final types = VariableRegistry.getByCategory(_selectedCategory!);
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: types.length,
      itemBuilder: (context, index) {
        final def = types[index];
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
              _descController.text = def.description;
            });
          },
        );
      },
    );
  }

  Widget _buildConfiguration() {
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
            labelText: 'Variable Name',
            border: OutlineInputBorder(),
            helperText: 'Must be unique and not empty.',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          decoration: const InputDecoration(
            labelText: 'Description (Optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Variable'),
      content: SizedBox(
        width: double.maxFinite,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              if (_canProceed) setState(() => _currentStep += 1);
            } else {
              _createVariable();
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
              title: const Text('Category'),
              content: _buildCategorySelection(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Type'),
              content: _buildTypeSelection(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Configure'),
              content: _buildConfiguration(),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }
}
