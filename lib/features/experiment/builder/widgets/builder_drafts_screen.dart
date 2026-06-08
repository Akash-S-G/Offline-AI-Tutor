import 'package:flutter/material.dart';
import '../storage/builder_draft_manager.dart';
import '../../../../core/widgets/idp_core_widgets.dart';
import '../../../../core/theme/idp_colors.dart';
import '../../../../core/theme/idp_theme.dart';

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.science_outlined, size: 64, color: Color(0xFF94A3B8)),
                const SizedBox(height: IDPSpacing.md),
                const Text('No Drafts Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: IDPColors.textPrimary)),
                const SizedBox(height: IDPSpacing.sm),
                const Text('Start by creating a new experiment in the AI Generator.', style: TextStyle(color: IDPColors.textSecondary)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(IDPSpacing.md),
          itemCount: drafts.length,
          itemBuilder: (context, index) {
            final d = drafts[index];
            final isCurrent = draftManager.currentDraftId == d.draftId;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: IDPSpacing.md),
              child: IDPCard(
                backgroundColor: isCurrent ? IDPColors.primaryLight : IDPColors.surface,
                child: ListTile(
                  title: Text(d.title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: IDPColors.textPrimary)),
                  subtitle: Text('Updated: ${d.updatedAt.toString().substring(0, 16)}', style: const TextStyle(color: IDPColors.textSecondary)),
                  leading: Icon(isCurrent ? Icons.check_circle_rounded : Icons.insert_drive_file_rounded, color: isCurrent ? IDPColors.success : IDPColors.textHint),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: IDPColors.textSecondary),
                        onPressed: () => draftManager.duplicateDraft(d.draftId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: IDPColors.error),
                        onPressed: () => draftManager.deleteDraft(d.draftId),
                      ),
                    ],
                  ),
                  onTap: () {
                    draftManager.loadDraft(d.draftId);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded ${d.title}')));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
