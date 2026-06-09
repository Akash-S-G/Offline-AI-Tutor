import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_object.dart';
import '../models/builder_variable.dart';
import 'object_runtime_config_editors.dart';
import '../wizards/object_wizard_dialog.dart';

class ObjectEditor extends StatelessWidget {
  final ExperimentBuilderController controller;

  const ObjectEditor({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final objects = controller.state.objects;
        final compact = MediaQuery.sizeOf(context).width < 380;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Objects',
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
                    label: Text(compact ? 'Add' : 'Add Object'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final newObj = await showDialog<BuilderObject>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => ObjectWizardDialog(
                          availableVariables: controller.state.variables,
                        ),
                      );

                      if (newObj != null) {
                        controller.addObject(newObj);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: objects.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      primary: true,
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: objects.length,
                      itemBuilder: (context, index) {
                        final o = objects[index];
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
                              Icons.category_rounded,
                              color: Color(0xFF10B981),
                            ),
                            title: Text(
                              o.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Type: ${o.type} | Config: ${o.runtimeConfig.length}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'view') {
                                  _showObjectDetails(context, o);
                                } else if (action == 'edit') {
                                  _showEditObjectDialog(context, controller, o);
                                } else if (action == 'delete') {
                                  controller.deleteObject(o.id);
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

  void _showObjectDetails(BuildContext context, BuilderObject object) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(object.name),
        content: SelectableText(
          'ID: ${object.id}\nType: ${object.type}\nProperties: ${object.properties}\nRuntime Config: ${object.runtimeConfig}',
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

  void _showEditObjectDialog(
    BuildContext context,
    ExperimentBuilderController controller,
    BuilderObject object,
  ) {
    final nameController = TextEditingController(text: object.name);
    final typeController = TextEditingController(text: object.type);
    BuilderVariable? linkedVariable;
    final linkedId = object.properties['linked_variable'];
    var runtimeConfig = Map<String, dynamic>.from(object.runtimeConfig);
    for (final variable in controller.state.variables) {
      if (variable.id == linkedId) {
        linkedVariable = variable;
        break;
      }
    }

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Object'),
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
                DropdownButtonFormField<BuilderVariable>(
                  isExpanded: true,
                  initialValue: linkedVariable,
                  decoration: const InputDecoration(
                    labelText: 'Linked Variable',
                  ),
                  items: controller.state.variables
                      .map(
                        (variable) => DropdownMenuItem(
                          value: variable,
                          child: Text('${variable.name} (${variable.id})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() {
                    linkedVariable = value;
                    if (typeController.text.trim() == 'lineGraph') {
                      runtimeConfig = {
                        ...runtimeConfig,
                        'variableId': value?.id,
                        'yAxis': value?.name ?? runtimeConfig['yAxis'] ?? '',
                      };
                    }
                  }),
                ),
                const SizedBox(height: 16),
                RuntimeObjectConfigEditor(
                  objectType: typeController.text.trim(),
                  variables: controller.state.variables,
                  config: runtimeConfig,
                  onChanged: (config) => setDialogState(() {
                    runtimeConfig = config;
                    if (typeController.text.trim() == 'lineGraph') {
                      final variableId = config['variableId']?.toString();
                      linkedVariable = controller.state.variables
                          .where((variable) => variable.id == variableId)
                          .firstOrNull;
                    }
                  }),
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
                final properties = Map<String, dynamic>.from(object.properties);
                if (linkedVariable != null) {
                  properties['linked_variable'] = linkedVariable!.id;
                } else {
                  properties.remove('linked_variable');
                }
                properties.addAll(
                  _runtimePropertiesFor(
                    typeController.text.trim(),
                    runtimeConfig,
                  ),
                );
                controller.editObject(
                  object.copyWith(
                    name: nameController.text.trim(),
                    type: typeController.text.trim(),
                    properties: properties,
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

  Map<String, dynamic> _runtimePropertiesFor(
    String objectType,
    Map<String, dynamic> runtimeConfig,
  ) {
    switch (objectType) {
      case 'scatterPlot':
        return {
          'xVariable': runtimeConfig['xVariable'],
          'yVariable': runtimeConfig['yVariable'],
        };
      case 'lineGraph':
        return {'linked_variable': runtimeConfig['variableId']};
      case 'table':
        return const {};
      default:
        return const {};
    }
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.widgets_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Create your first object',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Objects represent visual components in the experiment scene.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examples:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Line Graph',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                ),
                Text(
                  '• Pendulum Bob',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                ),
                Text(
                  '• Text Gauge',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
