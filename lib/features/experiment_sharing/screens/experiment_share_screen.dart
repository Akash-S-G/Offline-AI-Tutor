import 'package:flutter/material.dart';
import '../controllers/experiment_sharing_controller.dart';
import '../widgets/package_preview_panel.dart';
import '../../experiment/builder/storage/builder_draft_manager.dart';

class ExperimentShareScreen extends StatelessWidget {
  final ExperimentSharingController sharingController;
  final BuilderDraftManager draftManager;

  const ExperimentShareScreen({
    super.key,
    required this.sharingController,
    required this.draftManager,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Experiments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import .pihubexp',
            onPressed: sharingController.beginImportFlow,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([sharingController, draftManager]),
        builder: (context, _) {
          return Stack(
            children: [
              // Main List
              if (draftManager.drafts.isEmpty)
                const Center(child: Text('No drafts available to share.'))
              else
                ListView.builder(
                  itemCount: draftManager.drafts.length,
                  itemBuilder: (context, index) {
                    final draft = draftManager.drafts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.science),
                        title: Text(draft.title),
                        subtitle: Text('Last updated: ${draft.updatedAt.toString().substring(0, 16)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.ios_share),
                          tooltip: 'Export',
                          onPressed: sharingController.isLoading ? null : () async {
                            await sharingController.exportDraft(draft.title, draft.manifest);
                            if (sharingController.error != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(sharingController.error!)),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),

              // Loading Overlay
              if (sharingController.isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),

              // Preview Overlay
              if (sharingController.previewPackage != null && !sharingController.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black87,
                    child: Center(
                      child: SingleChildScrollView(
                        child: PackagePreviewPanel(controller: sharingController),
                      ),
                    ),
                  ),
                ),
                
              // Error SnackBar (handled mostly via Listenable side effects or callbacks, but we can do a simple display)
              if (sharingController.error != null && sharingController.previewPackage == null && !sharingController.isLoading)
                Positioned(
                  bottom: 16, left: 16, right: 16,
                  child: Card(
                    color: Colors.red,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(sharingController.error!, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
