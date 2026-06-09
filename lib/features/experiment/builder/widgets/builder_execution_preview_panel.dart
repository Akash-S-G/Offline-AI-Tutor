import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';

import '../../../shared/presentation/widgets/error_state_card.dart';
import '../../domain/models/experiment_models.dart';
import '../../domain/enums/experiment_enums.dart';
import '../../presentation/screens/experiment_player_screen.dart';

class BuilderExecutionPreviewPanel extends StatelessWidget {
  final ExperimentBuilderController controller;

  const BuilderExecutionPreviewPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pkg = controller.executionPackage;
        return SingleChildScrollView(
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
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text('Mode: ${pkg['mode'] ?? 'unknown'}'),
                              backgroundColor: Colors.blue.shade50,
                            ),
                            Chip(
                              label: Text('Coverage: ${pkg['coveragePercentage'] ?? 0}%'),
                              backgroundColor: Colors.green.shade50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Missing Sensors:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text((pkg['missingSensors'] as List<dynamic>? ?? []).join(", ")),
                        const Divider(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text('Variables: ${(pkg['variables'] as List<dynamic>? ?? []).length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Objects: ${(pkg['objects'] as List<dynamic>? ?? []).length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Rules: ${(pkg['rules'] as List<dynamic>? ?? []).length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final scene = controller.state.scene;
                              final manifest = ExperimentManifest(
                                id: scene.id,
                                title: scene.name,
                                description: scene.description,
                                subject: 'Physics', // Mock
                                grade: '10th', // Mock
                                chapter: 'Builder', // Mock
                                topic: 'Custom', // Mock
                                difficulty: ExperimentDifficulty.medium,
                                requiredSensors: List<String>.from(pkg['missingSensors'] ?? []),
                                supportedModes: [ExperimentExecutionMode.simulation],
                                steps: [],
                                visualizations: [],
                                estimatedDurationMinutes: 10,
                                supportsSimulation: true,
                                supportsSensorExecution: false,
                                supportsObservationMode: false,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExperimentPlayerScreen(manifest: manifest, executionPayload: pkg as Map<String,dynamic>?),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Launch Runtime'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
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
