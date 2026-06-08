import 'package:flutter/material.dart';
import '../storage/builder_draft_manager.dart';

class BuilderDraftsScreen extends StatelessWidget {
  final BuilderDraftManager draftManager;

  const BuilderDraftsScreen({super.key, required this.draftManager});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: draftManager,
      builder: (context, _) {
        final drafts = draftManager.drafts;
        if (drafts.isEmpty) {
          return const Center(child: Text('No saved drafts.'));
        }
        
        return ListView.builder(
          itemCount: drafts.length,
          itemBuilder: (context, index) {
            final d = drafts[index];
            final isCurrent = draftManager.currentDraftId == d.draftId;
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(d.title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text('Updated: ${d.updatedAt.toString().substring(0, 16)}'),
                leading: Icon(isCurrent ? Icons.check_circle : Icons.insert_drive_file, color: isCurrent ? Colors.green : Colors.grey),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => draftManager.duplicateDraft(d.draftId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => draftManager.deleteDraft(d.draftId),
                    ),
                  ],
                ),
                onTap: () {
                  draftManager.loadDraft(d.draftId);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded ${d.title}')));
                },
              ),
            );
          },
        );
      },
    );
  }
}
