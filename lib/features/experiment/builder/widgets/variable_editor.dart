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
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Variable'),
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
            ),
            Expanded(
              child: ListView.builder(
                itemCount: vars.length,
                itemBuilder: (context, index) {
                  final v = vars[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(v.name),
                      subtitle: Text('Type: ${v.type} | Default: ${v.defaultValue}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
}
