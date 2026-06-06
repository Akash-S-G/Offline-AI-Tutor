// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../domain/models/experiment_models.dart';
import '../../domain/enums/experiment_enums.dart';
import '../widgets/experiment_card.dart';
import 'experiment_details_screen.dart';

class ExperimentCatalogScreen extends StatefulWidget {
  const ExperimentCatalogScreen({super.key});

  @override
  State<ExperimentCatalogScreen> createState() => _ExperimentCatalogScreenState();
}

class _ExperimentCatalogScreenState extends State<ExperimentCatalogScreen> {
  final List<ExperimentManifest> _experiments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    print('[EXPERIMENT_UI] CATALOG_LOAD');
    setState(() => _isLoading = true);

    // Placeholder for GET /experiments
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data for UI Foundation
    _experiments.add(ExperimentManifest(
      id: 'demo_1',
      title: 'Simple Pendulum',
      description: 'Explore the physics of a simple pendulum.',
      subject: 'Physics',
      grade: '10th',
      chapter: 'Mechanics',
      topic: 'Motion',
      difficulty: ExperimentDifficulty.easy,
      requiredSensors: ['accelerometer'],
      supportedModes: [ExperimentExecutionMode.simulation, ExperimentExecutionMode.observation],
      steps: [],
      visualizations: [],
      estimatedDurationMinutes: 10,
      supportsSimulation: true,
      supportsSensorExecution: true,
      supportsObservationMode: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment Catalog'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _experiments.length,
              itemBuilder: (context, index) {
                final manifest = _experiments[index];
                return ExperimentCard(
                  manifest: manifest,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExperimentDetailsScreen(manifest: manifest),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
