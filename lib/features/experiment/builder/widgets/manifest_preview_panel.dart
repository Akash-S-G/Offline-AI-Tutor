import 'package:flutter/material.dart';
import 'dart:convert';
import '../controllers/experiment_builder_controller.dart';

class ManifestPreviewPanel extends StatelessWidget {
  final ExperimentBuilderController controller;

  const ManifestPreviewPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final manifest = controller.generateManifest();
        final jsonString = const JsonEncoder.withIndent('  ').convert(manifest);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Generated Execution Definition', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      jsonString,
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
