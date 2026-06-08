import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';

class BuilderCompatibilityPanel extends StatelessWidget {
  final ExperimentBuilderController controller;

  const BuilderCompatibilityPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final result = controller.compatibilityResult;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: controller.isLoading ? null : () => controller.checkCompatibility(),
                icon: const Icon(Icons.verified),
                label: const Text('Check Compatibility'),
              ),
              const SizedBox(height: 16),
              if (controller.isLoading) const Center(child: CircularProgressIndicator()),
              if (result != null && !controller.isLoading) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manifest Version: ${result.manifestVersion}'),
                        Text('Supported: ${result.supported}'),
                        Text('Target Version: ${result.targetVersion}'),
                        if (result.migrationRequired) ...[
                          const SizedBox(height: 16),
                          const Text('Migration Required!', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => controller.migrateManifest(),
                            child: const Text('Apply Migration'),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
