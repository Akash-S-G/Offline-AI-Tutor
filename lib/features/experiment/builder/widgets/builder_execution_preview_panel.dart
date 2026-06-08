import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';

import '../../../shared/presentation/widgets/error_state_card.dart';

class BuilderExecutionPreviewPanel extends StatelessWidget {
  final ExperimentBuilderController controller;

  const BuilderExecutionPreviewPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pkg = controller.executionPackage;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: controller.isLoading ? null : () => controller.fetchExecutionPackage(),
                icon: const Icon(Icons.memory),
                label: const Text('Fetch Execution Package'),
              ),
              const SizedBox(height: 16),
              if (controller.isLoading) const Center(child: CircularProgressIndicator()),
              if (controller.error != null && !controller.isLoading) 
                ErrorStateCard(
                  error: controller.error!,
                  onRetry: () => controller.fetchExecutionPackage(),
                ),
              if (pkg != null && !controller.isLoading && controller.error == null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Execution Mode: ${pkg['mode'] ?? 'unknown'}'),
                        Text('Coverage: ${pkg['coveragePercentage'] ?? 0}%'),
                        const SizedBox(height: 8),
                        const Text('Missing Sensors:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text((pkg['missingSensors'] as List<dynamic>? ?? []).join(", ")),
                        const Divider(),
                        Text('Variables: ${(pkg['variables'] as List<dynamic>? ?? []).length}'),
                        Text('Objects: ${(pkg['objects'] as List<dynamic>? ?? []).length}'),
                        Text('Rules: ${(pkg['rules'] as List<dynamic>? ?? []).length}'),
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
