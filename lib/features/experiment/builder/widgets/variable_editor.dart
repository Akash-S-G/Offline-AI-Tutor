import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_variable.dart';
import 'builder_search_bar.dart';
import 'empty_state_card.dart';
import 'variable_runtime_config_editors.dart';
import '../wizards/variable_wizard_dialog.dart';

class VariableEditor extends StatefulWidget {
  final ExperimentBuilderController controller;

  const VariableEditor({super.key, required this.controller});

  @override
  State<VariableEditor> createState() => _VariableEditorState();
}

class _VariableEditorState extends State<VariableEditor> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final vars = BuilderSearchBar.filter(
          widget.controller.state.variables,
          _query,
          (variable) => [variable.name, variable.id, variable.type],
        );
        final compact = MediaQuery.sizeOf(context).width < 380;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Variables (${widget.controller.state.variables.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(compact ? 'Add' : 'Add Variable'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final newVar = await showDialog<BuilderVariable>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => VariableWizardDialog(
                          availableVariables: widget.controller.state.variables,
                        ),
                      );

                      if (newVar != null) {
                        widget.controller.addVariable(newVar);
                      }
                    },
                  ),
                ],
              ),
            ),
            BuilderSearchBar(
              hintText: 'Search Variables',
              onChanged: (value) => setState(() => _query = value),
            ),
            const Divider(height: 1),
            Expanded(
              child: widget.controller.state.variables.isEmpty
                  ? _buildEmptyState(context)
                  : vars.isEmpty
                  ? const Center(child: Text('No matching variables'))
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      primary: true,
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: vars.length,
                      itemBuilder: (context, index) {
                        final v = vars[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.data_object_rounded,
                              color: Color(0xFF3B82F6),
                            ),
                            title: Text(
                              v.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Type: ${v.type} | Config: ${v.runtimeConfig.length}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'view') {
                                  _showVariableDetails(context, v);
                                } else if (action == 'edit') {
                                  _showEditVariableDialog(
                                    context,
                                    widget.controller,
                                    v,
                                  );
                                } else if (action == 'delete') {
                                  widget.controller.deleteVariable(v.id);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Text('View'),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showVariableDetails(BuildContext context, BuilderVariable variable) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(variable.name),
        content: SelectableText(
          'ID: ${variable.id}\nType: ${variable.type}\nDefault: ${variable.defaultValue}\nDescription: ${variable.description}\nRuntime Config: ${variable.runtimeConfig}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditVariableDialog(
    BuildContext context,
    ExperimentBuilderController controller,
    BuilderVariable variable,
  ) {
    final nameController = TextEditingController(text: variable.name);
    final typeController = TextEditingController(text: variable.type);
    final defaultController = TextEditingController(
      text: '${variable.defaultValue ?? ''}',
    );
    final descController = TextEditingController(text: variable.description);
    var runtimeConfig = Map<String, dynamic>.from(variable.runtimeConfig);

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Variable'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(
                  controller: defaultController,
                  decoration: const InputDecoration(labelText: 'Default Value'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                RuntimeVariableConfigEditor(
                  variableType: typeController.text.trim(),
                  variables: controller.state.variables,
                  currentVariableId: variable.id,
                  config: runtimeConfig,
                  onChanged: (config) => setDialogState(() {
                    runtimeConfig = config;
                  }),
                ),
                DependencyTreePreview(
                  formulaName: typeController.text.trim(),
                  dependencyIds: _dependencyIdsFor(
                    typeController.text.trim(),
                    runtimeConfig,
                  ),
                  variables: controller.state.variables,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.editVariable(
                  variable.copyWith(
                    name: nameController.text.trim(),
                    type: typeController.text.trim(),
                    defaultValue:
                        num.tryParse(defaultController.text) ??
                        defaultController.text,
                    description: descController.text.trim(),
                    runtimeConfig: runtimeConfig,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _dependencyIdsFor(String type, Map<String, dynamic> config) {
    switch (type) {
      case 'average':
      case 'minimum':
      case 'maximum':
        final dependencies = config['dependencies'];
        if (dependencies is List) {
          return dependencies
              .map((entry) => entry.toString())
              .toList(growable: false);
        }
        return const [];
      case 'distance':
        return _ids(config, ['speedVariable', 'timeVariable']);
      case 'velocity':
        return _ids(config, ['distanceVariable', 'timeVariable']);
      case 'acceleration':
        return _ids(config, ['velocityVariable', 'timeVariable']);
      case 'force':
        return _ids(config, ['massVariable', 'accelerationVariable']);
      case 'power':
        return _ids(config, ['forceVariable', 'velocityVariable']);
      case 'energy':
        return _ids(config, ['powerVariable', 'timeVariable']);
      default:
        return const [];
    }
  }

  List<String> _ids(Map<String, dynamic> config, List<String> keys) {
    return keys
        .map((key) => config[key]?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.data_array_rounded,
      title: 'No Variables Yet',
      message: 'Variables track dynamic values during the experiment.',
      primaryLabel: 'Create Variable',
      onPrimary: () async {
        final newVar = await showDialog<BuilderVariable>(
          context: context,
          barrierDismissible: false,
          builder: (context) => VariableWizardDialog(
            availableVariables: widget.controller.state.variables,
          ),
        );
        if (newVar != null && mounted) widget.controller.addVariable(newVar);
      },
      secondaryLabel: 'Import Template',
      onSecondary: null,
    );
  }
}
