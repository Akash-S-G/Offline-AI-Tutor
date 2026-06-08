import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_variable.dart';
import 'package:uuid/uuid.dart';
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Variable'),
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
                      itemCount: vars.length,
                      itemBuilder: (context, index) {
                        final v = vars[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.data_object_rounded, color: Color(0xFF3B82F6)),
                            title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Type: ${v.type} | Default: ${v.defaultValue}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => controller.deleteVariable(v.id),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.data_array_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Create your first variable',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                Text('Examples:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                SizedBox(height: 4),
                Text('• Temperature', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                Text('• Velocity', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                Text('• Time Elapsed', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
