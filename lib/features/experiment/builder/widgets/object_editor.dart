import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_object.dart';
import 'package:uuid/uuid.dart';
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Object'),
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
                      itemCount: objects.length,
                      itemBuilder: (context, index) {
                        final o = objects[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.category_rounded, color: Color(0xFF10B981)),
                            title: Text(o.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Type: ${o.type} | Props: ${o.properties.length}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => controller.deleteObject(o.id),
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
          Icon(Icons.widgets_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Create your first object',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                Text('Examples:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                SizedBox(height: 4),
                Text('• Line Graph', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                Text('• Pendulum Bob', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                Text('• Text Gauge', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
