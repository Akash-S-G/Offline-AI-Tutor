import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_rule.dart';
import 'package:uuid/uuid.dart';
import '../wizards/rule_wizard_dialog.dart';

class RuleEditor extends StatelessWidget {
  final ExperimentBuilderController controller;

  const RuleEditor({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final rules = controller.state.rules;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Rule'),
                onPressed: () async {
                  final newRule = await showDialog<BuilderRule>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => RuleWizardDialog(
                      availableVariables: controller.state.variables,
                    ),
                  );

                  if (newRule != null) {
                    controller.addRule(newRule);
                  }
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final r = rules[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(r.name),
                      subtitle: Text('Trigger: any'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => controller.deleteRule(r.id),
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
