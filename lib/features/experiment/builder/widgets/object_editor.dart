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
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Object'),
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
            ),
            Expanded(
              child: ListView.builder(
                itemCount: objects.length,
                itemBuilder: (context, index) {
                  final o = objects[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(o.name),
                      subtitle: Text('Type: ${o.type} | Props: ${o.properties.length}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
}
