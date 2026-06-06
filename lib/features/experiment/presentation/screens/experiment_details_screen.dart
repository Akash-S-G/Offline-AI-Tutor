// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../domain/models/experiment_models.dart';
import '../widgets/execution_mode_chip.dart';
import 'experiment_player_screen.dart';

class ExperimentDetailsScreen extends StatefulWidget {
  final ExperimentManifest manifest;

  const ExperimentDetailsScreen({super.key, required this.manifest});

  @override
  State<ExperimentDetailsScreen> createState() => _ExperimentDetailsScreenState();
}

class _ExperimentDetailsScreenState extends State<ExperimentDetailsScreen> {
  @override
  void initState() {
    super.initState();
    print('[EXPERIMENT_UI] DETAILS_LOAD');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.manifest.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.manifest.subject} • ${widget.manifest.topic} • ${widget.manifest.difficulty.name.toUpperCase()}',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.manifest.description),
            const SizedBox(height: 16),
            const Text('Required Sensors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.manifest.requiredSensors
                  .map((s) => Chip(label: Text(s), avatar: const Icon(Icons.sensors, size: 16)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Supported Modes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.manifest.supportedModes
                  .map((mode) => ExecutionModeChip(mode: mode))
                  .toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExperimentPlayerScreen(manifest: widget.manifest),
                    ),
                  );
                },
                child: const Text('START EXPERIMENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
