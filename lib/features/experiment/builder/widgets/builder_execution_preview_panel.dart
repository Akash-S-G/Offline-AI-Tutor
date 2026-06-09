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
        final validation = controller.currentValidation;
        final state = controller.state;
        final isEmptyManifest =
            state.variables.isEmpty &&
            state.objects.isEmpty &&
            state.rules.isEmpty;
        final canFetch =
            !controller.isLoading && !isEmptyManifest && validation.isValid;
        final scene = pkg?['scene'] as Map<String, dynamic>?;
        final variables = scene?['variables'] as List<dynamic>? ?? [];
        final objects = scene?['objects'] as List<dynamic>? ?? [];
        final rules = scene?['rules'] as List<dynamic>? ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: canFetch
                    ? () => controller.fetchExecutionPackage()
                    : null,
                icon: const Icon(Icons.memory),
                label: const Text('Fetch Execution Package'),
              ),
              const SizedBox(height: 16),
              _buildManifestInspector(validation, isEmptyManifest),
              const SizedBox(height: 16),
              if (controller.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (controller.error != null && !controller.isLoading)
                ErrorStateCard(
                  error: controller.error!,
                  onRetry: () => controller.fetchExecutionPackage(),
                ),
              if (pkg != null &&
                  !controller.isLoading &&
                  controller.error == null) ...[
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
                              label: Text(
                                'Coverage: ${pkg['coveragePercentage'] ?? 0}%',
                              ),
                              backgroundColor: Colors.green.shade50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Missing Sensors:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (pkg['missingSensors'] as List<dynamic>? ?? []).join(
                            ", ",
                          ),
                        ),
                        const Divider(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Variables: ${variables.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Objects: ${objects.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rules: ${rules.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                requiredSensors: List<String>.from(
                                  pkg['missingSensors'] ?? [],
                                ),
                                supportedModes: [
                                  ExperimentExecutionMode.simulation,
                                ],
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
                                  builder: (_) => ExperimentPlayerScreen(
                                    manifest: manifest,
                                    executionPayload:
                                        pkg as Map<String, dynamic>?,
                                  ),
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

  Widget _buildManifestInspector(dynamic validation, bool isEmptyManifest) {
    final state = controller.state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Manifest Inspector',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Chip(label: Text('Objects: ${state.objects.length}')),
                Chip(label: Text('Variables: ${state.variables.length}')),
                Chip(label: Text('Rules: ${state.rules.length}')),
              ],
            ),
            const SizedBox(height: 12),
            _idSection(
              'Variable IDs',
              state.variables
                  .map((item) => '${item.name}: ${item.id}')
                  .toList(),
            ),
            _idSection(
              'Object IDs',
              state.objects.map((item) => '${item.name}: ${item.id}').toList(),
            ),
            _idSection(
              'Rule IDs',
              state.rules.map((item) => '${item.name}: ${item.id}').toList(),
            ),
            if (isEmptyManifest) ...[
              const SizedBox(height: 12),
              const Text(
                'Manifest is empty. Add variables, objects, or rules before preparing runtime.',
                style: TextStyle(color: Colors.red),
              ),
            ],
            if (!validation.isValid) ...[
              const SizedBox(height: 12),
              ...validation.errors.map<Widget>(
                (error) =>
                    Text(error, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _idSection(String title, List<String> ids) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (ids.isEmpty)
            const Text('None', style: TextStyle(color: Colors.grey))
          else
            ...ids.map(
              (id) => Text(id, style: const TextStyle(fontFamily: 'monospace')),
            ),
        ],
      ),
    );
  }
}
