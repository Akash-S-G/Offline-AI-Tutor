import 'package:flutter/material.dart';
import '../controllers/experiment_sharing_controller.dart';

class PackagePreviewPanel extends StatelessWidget {
  final ExperimentSharingController controller;

  const PackagePreviewPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pkg = controller.previewPackage;
        if (pkg == null) return const SizedBox.shrink();

        final scene = pkg.manifest['scene'] as Map<String, dynamic>? ?? {};
        final vars = scene['variables'] as List<dynamic>? ?? [];
        final objs = scene['objects'] as List<dynamic>? ?? [];
        final rules = scene['rules'] as List<dynamic>? ?? [];

        final validation = controller.validationResult;
        final isImportable = validation?.isValid == true;

        return Card(
          elevation: 6,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Import Preview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: controller.clearPreview),
                  ],
                ),
                const Divider(),
                
                // Trust Indicators
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Verified Signature', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Author: ${pkg.author}'),
                Text('Version: ${pkg.version}'),
                Text('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(pkg.timestamp).toString()}'),
                
                const Divider(),
                // Contents
                const Text('Contents', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• ${vars.length} Variables'),
                Text('• ${objs.length} Objects'),
                Text('• ${rules.length} Rules'),
                
                const Divider(),
                // Validation Status
                if (validation != null) ...[
                  if (validation.isValid)
                    const Text('Validation: Passed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                  else ...[
                    const Text('Validation: Failed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ...validation.errors.map((e) => Text('- $e', style: const TextStyle(color: Colors.red, fontSize: 12))),
                  ]
                ] else
                  const Text('Validation: Pending...'),

                const SizedBox(height: 16),
                
                // Action Buttons
                ElevatedButton.icon(
                  onPressed: isImportable ? controller.importToDrafts : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Import To Drafts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isImportable ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
