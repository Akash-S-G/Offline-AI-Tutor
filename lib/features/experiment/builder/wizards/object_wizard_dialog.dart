import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/object_registry.dart';
import '../models/builder_object.dart';
import '../models/builder_variable.dart';
import '../widgets/object_runtime_config_editors.dart';

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
  Map<String, dynamic> _runtimeConfig = const {};

  bool get _canProceed {
    if (_currentStep == 0) return _selectedType != null;
    if (_currentStep == 1) {
      return _nameController.text.trim().isNotEmpty && _configIsValid;
    }
    return false;
  }

  bool get _configIsValid {
    final type = _selectedType?.type.name;
    switch (type) {
      case 'scatterPlot':
        final x = _runtimeConfig['xVariable']?.toString();
        final y = _runtimeConfig['yVariable']?.toString();
        return x != null && x.isNotEmpty && y != null && y.isNotEmpty && x != y;
      case 'table':
        return true;
      case 'lineGraph':
        return _runtimeConfig['variableId']?.toString().isNotEmpty == true;
      default:
        return _linkedVariable != null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createObject() {
    if (!_canProceed) return;
    final properties = _propertiesForSelectedType();

    final newObj = BuilderObject(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _selectedType!.type.name,
      properties: properties,
      runtimeConfig: _runtimeConfig,
    );

    Navigator.of(context).pop(newObj);
  }

  Widget _buildTypeSelection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        return GridView.builder(
          key: const PageStorageKey<String>('object_wizard_type_grid'),
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
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
                  _runtimeConfig = _defaultConfigFor(def, _linkedVariable);
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
              if (_selectedType?.type.name == 'lineGraph') {
                _runtimeConfig = {
                  ..._runtimeConfig,
                  'variableId': val?.id,
                  'yAxis': val?.name ?? _runtimeConfig['yAxis'] ?? '',
                };
              }
            });
          },
        ),
        const SizedBox(height: 16),
        RuntimeObjectConfigEditor(
          objectType: _selectedType?.type.name ?? '',
          variables: compatibleVars,
          config: _runtimeConfig,
          onChanged: (config) {
            setState(() {
              _runtimeConfig = config;
              if (_selectedType?.type.name == 'lineGraph') {
                final variableId = config['variableId']?.toString();
                _linkedVariable = compatibleVars
                    .where((variable) => variable.id == variableId)
                    .firstOrNull;
              }
            });
          },
        ),
        if (_selectedType?.type.name == 'scatterPlot' &&
            !_scatterSelectionValid)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Choose different X and Y variables for the scatter plot.',
              style: TextStyle(color: Colors.red),
            ),
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

  bool get _scatterSelectionValid {
    final x = _runtimeConfig['xVariable']?.toString();
    final y = _runtimeConfig['yVariable']?.toString();
    return x != null && x.isNotEmpty && y != null && y.isNotEmpty && x != y;
  }

  Map<String, dynamic> _propertiesForSelectedType() {
    final type = _selectedType!.type.name;
    switch (type) {
      case 'scatterPlot':
        return {
          'xVariable': _runtimeConfig['xVariable'],
          'yVariable': _runtimeConfig['yVariable'],
        };
      case 'lineGraph':
        return {'linked_variable': _runtimeConfig['variableId']};
      case 'table':
        return const {};
      default:
        return {
          if (_linkedVariable != null) 'linked_variable': _linkedVariable!.id,
        };
    }
  }

  Map<String, dynamic> _defaultConfigFor(
    ObjectDefinition definition,
    BuilderVariable? linkedVariable,
  ) {
    final variableId = linkedVariable?.id;
    switch (definition.type.name) {
      case 'numericDisplay':
        return {
          'label': linkedVariable?.name ?? 'Value',
          'unit': '',
          'precision': 1,
        };
      case 'gauge':
        return {'min': 0, 'max': 100, 'unit': '', 'warningThreshold': 80};
      case 'progressBar':
        return {'min': 0, 'max': 100};
      case 'lineGraph':
        return {
          'variableId': variableId,
          'historyWindow': 100,
          'xAxis': 'Time',
          'yAxis': linkedVariable?.name ?? '',
        };
      case 'scatterPlot':
        return {
          'xVariable': widget.availableVariables.isNotEmpty
              ? widget.availableVariables.first.id
              : null,
          'yVariable': widget.availableVariables.length > 1
              ? widget.availableVariables[1].id
              : null,
        };
      case 'table':
        return {'maxRows': 100, 'autoRecord': true};
      default:
        return const {};
    }
  }

  String get _stepTitle =>
      _currentStep == 0 ? 'Choose Object Type' : 'Configure Object';

  Widget _buildCurrentStep() =>
      _currentStep == 0 ? _buildTypeSelection() : _buildConfiguration();

  Widget _buildStepHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_stepTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_currentStep + 1) / 2),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of 2',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
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
                  _buildStepHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const PageStorageKey<String>(
                        'object_wizard_step_scroll',
                      ),
                      controller: scrollController,
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
