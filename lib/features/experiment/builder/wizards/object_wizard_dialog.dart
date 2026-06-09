import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/object_registry.dart';
import '../models/builder_object.dart';
import '../models/builder_variable.dart';

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
    if (_currentStep == 1) {
      return _nameController.text.trim().isNotEmpty && _linkedVariable != null;
    }
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
      properties: {'linked_variable': _linkedVariable!.id},
    );

    Navigator.of(context).pop(newObj);
  }

  Widget _buildTypeSelection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 150,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: ObjectRegistry.definitions.length,
      itemBuilder: (context, index) {
        final def = ObjectRegistry.definitions[index];
        final selected = _selectedType == def;
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(12),
            side: BorderSide(
              color: selected ? Colors.blue : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            backgroundColor: selected
                ? Colors.blue.withValues(alpha: 0.08)
                : null,
          ),
          onPressed: () {
            setState(() {
              _selectedType = def;
              _nameController.text = def.title.toLowerCase().replaceAll(
                ' ',
                '_',
              );
              _linkedVariable = _getCompatibleVariables(def).firstOrNull;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                def.icon,
                color: selected ? Colors.blue : Colors.grey.shade700,
              ),
              const SizedBox(height: 8),
              Text(
                def.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  def.description,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Text(
                'Example: link to a live value',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
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
    final compatibleVars = _selectedType != null
        ? _getCompatibleVariables(_selectedType!)
        : <BuilderVariable>[];

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
          initialValue: _linkedVariable,
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
            child: Text(
              'No compatible variables found. Please create a variable first.',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, scrollController) {
          return Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Add Object',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Stepper(
                        currentStep: _currentStep,
                        controlsBuilder: (context, details) =>
                            const SizedBox.shrink(),
                        steps: [
                          Step(
                            title: const Text('Visualization Type'),
                            content: _buildTypeSelection(),
                            isActive: _currentStep >= 0,
                            state: _currentStep > 0
                                ? StepState.complete
                                : StepState.indexed,
                          ),
                          Step(
                            title: const Text('Configure'),
                            content: _buildConfiguration(),
                            isActive: _currentStep >= 1,
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
                                    if (_currentStep < 1) {
                                      setState(() => _currentStep += 1);
                                    } else {
                                      _createObject();
                                    }
                                  }
                                : null,
                            child: Text(_currentStep == 1 ? 'Create' : 'Next'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
