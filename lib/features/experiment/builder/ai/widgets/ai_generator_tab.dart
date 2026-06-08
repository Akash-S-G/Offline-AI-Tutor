import 'package:flutter/material.dart';
import 'dart:convert';
import '../controllers/ai_generator_controller.dart';
import '../../controllers/experiment_builder_controller.dart';

class AiGeneratorTab extends StatefulWidget {
  final AiGeneratorController aiController;
  final ExperimentBuilderController builderController;

  const AiGeneratorTab({
    super.key,
    required this.aiController,
    required this.builderController,
  });

  @override
  State<AiGeneratorTab> createState() => _AiGeneratorTabState();
}

class _AiGeneratorTabState extends State<AiGeneratorTab> {
  final TextEditingController _promptController = TextEditingController();

  void _onGenerate() {
    if (_promptController.text.trim().isEmpty) return;
    widget.aiController.generateExperiment(_promptController.text.trim());
  }

  void _onRefine() {
    if (_promptController.text.trim().isEmpty) return;
    widget.aiController.refineExperiment(_promptController.text.trim());
  }

  void _onImport() {
    final manifest = widget.aiController.generatedManifest;
    if (manifest != null && widget.aiController.canImport) {
      widget.builderController.loadFromManifest(manifest);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully imported AI draft to Builder!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.aiController,
      builder: (context, _) {
        final ai = widget.aiController;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _promptController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Describe the experiment...',
                  hintText: 'e.g. Create a pendulum experiment using accelerometer for grade 6 students',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ai.isLoading ? null : _onGenerate,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (ai.isLoading || ai.generatedManifest == null) ? null : _onRefine,
                      icon: const Icon(Icons.edit),
                      label: const Text('Refine Draft'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (ai.isLoading) const Center(child: CircularProgressIndicator()),
              if (ai.error != null)
                Card(color: Colors.red.shade100, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                  const Text('Offline State / Error', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  Text(ai.error!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(onPressed: _onGenerate, child: const Text('Retry'))
                ]))),
              if (ai.generatedManifest != null && !ai.isLoading)
                ...[
                  _buildImportSection(ai),
                  const SizedBox(height: 16),
                  _buildExplanationPanel(ai),
                  const SizedBox(height: 16),
                  _buildValidationPanel(ai),
                  const SizedBox(height: 16),
                  _buildCompatibilityPanel(ai),
                  const SizedBox(height: 16),
                  _buildExecutionPreviewPanel(ai),
                  const SizedBox(height: 16),
                  _buildManifestPreview(ai),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildImportSection(AiGeneratorController ai) {
    return Card(
      elevation: 4,
      color: ai.canImport ? Colors.green.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: ai.canImport ? _onImport : null,
              icon: const Icon(Icons.download),
              label: const Text('Import Into Builder', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ai.canImport ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            if (!ai.canImport)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Cannot import. Must pass validation and compatibility checks first.', style: TextStyle(color: Colors.red, fontSize: 12)),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationPanel(AiGeneratorController ai) {
    final exp = ai.explanation;
    if (exp == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Explanation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('What this teaches: ${exp['teaches'] ?? 'N/A'}'),
            Text('Variables: ${(exp['variables'] as List<dynamic>? ?? []).join(", ")}'),
            Text('Objects: ${(exp['objects'] as List<dynamic>? ?? []).join(", ")}'),
            Text('Rules: ${(exp['rules'] as List<dynamic>? ?? []).join(", ")}'),
            Text('Modes: ${(exp['modes'] as List<dynamic>? ?? []).join(", ")}'),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationPanel(AiGeneratorController ai) {
    final v = ai.validationResult;
    if (v == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Validation Section', style: TextStyle(fontWeight: FontWeight.bold)),
            if (v.isValid)
              const Text('Validation Passed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            if (!v.isValid) ...[
              const Text('Validation Errors', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ...v.errors.map((e) => Text('• $e', style: const TextStyle(color: Colors.red))),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityPanel(AiGeneratorController ai) {
    final c = ai.compatibilityResult;
    if (c == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compatibility Section', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Manifest Version: ${c.manifestVersion}'),
            Text('Target Version: ${c.targetVersion}'),
            Text('Migration Needed: ${c.migrationRequired}', style: TextStyle(color: c.migrationRequired ? Colors.orange : Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionPreviewPanel(AiGeneratorController ai) {
    final pkg = ai.executionPackage;
    if (pkg == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Execution Preview', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Coverage: ${pkg['coveragePercentage'] ?? 0}%'),
            Text('Available Modes: ${(pkg['modes'] as List<dynamic>? ?? []).join(", ")}'),
            Text('Missing Sensors: ${(pkg['missingSensors'] as List<dynamic>? ?? []).join(", ")}'),
          ],
        ),
      ),
    );
  }

  Widget _buildManifestPreview(AiGeneratorController ai) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(ai.generatedManifest);
    return Card(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          jsonString,
          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 10),
        ),
      ),
    );
  }
}
