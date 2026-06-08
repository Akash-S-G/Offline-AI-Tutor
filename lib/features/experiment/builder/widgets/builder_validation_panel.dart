import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';

class BuilderValidationPanel extends StatelessWidget {
  final ExperimentBuilderController controller;

  const BuilderValidationPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final result = controller.apiValidationResult;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: controller.isLoading ? null : () => controller.validateWithBackend(),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Validate Manifest (Backend)'),
              ),
              const SizedBox(height: 16),
              if (controller.isLoading) const Center(child: CircularProgressIndicator()),
              if (result != null && !controller.isLoading) ...[
                if (result.isValid)
                  const Card(color: Colors.green, child: Padding(padding: EdgeInsets.all(16), child: Text('Valid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                if (!result.isValid)
                  const Card(color: Colors.red, child: Padding(padding: EdgeInsets.all(16), child: Text('Invalid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                
                if (result.warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...result.warnings.map((w) => Text('• $w', style: const TextStyle(color: Colors.orange))),
                ],
                
                if (result.errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...result.errors.map((e) => Text('• $e', style: const TextStyle(color: Colors.red))),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
