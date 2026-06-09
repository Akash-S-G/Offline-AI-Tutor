import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_variable.dart';
import '../wizards/variable_wizard_dialog.dart';

class VariableEditor extends StatelessWidget {
  final ExperimentBuilderController controller;

  const VariableEditor({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final vars = controller.state.variables;
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
                      'Variables',
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
                        builder: (context) => const VariableWizardDialog(),
                      );

                      if (newVar != null) {
                        controller.addVariable(newVar);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: vars.isEmpty
                  ? _buildEmptyState()
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
                              'Type: ${v.type} | Default: ${v.defaultValue}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'view') {
                                  _showVariableDetails(context, v);
                                } else if (action == 'edit') {
                                  _showEditVariableDialog(
                                    context,
                                    controller,
                                    v,
                                  );
                                } else if (action == 'delete') {
                                  controller.deleteVariable(v.id);
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
          'ID: ${variable.id}\nType: ${variable.type}\nDefault: ${variable.defaultValue}\nDescription: ${variable.description}',
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

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.data_array_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Create your first variable',
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
              'Variables track dynamic values during the experiment.',
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
                  '• Temperature',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                ),
                Text(
                  '• Velocity',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                ),
                Text(
                  '• Time Elapsed',
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
