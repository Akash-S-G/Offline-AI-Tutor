import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/idp_colors.dart';
import '../../../../core/theme/idp_typography.dart';
import '../../../course/domain/curriculum_experiment_mapper.dart';
import '../../builder/screens/experiment_builder_screen.dart';
import '../../builder/storage/builder_draft_manager.dart';
import '../../builder/storage/builder_draft_repository.dart';
import '../../builder/templates/experiment_templates.dart';
import 'experiment_details_screen.dart';
import 'experiment_player_screen.dart';

class TemplateGalleryScreen extends StatefulWidget {
  const TemplateGalleryScreen({super.key});

  @override
  State<TemplateGalleryScreen> createState() => _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends State<TemplateGalleryScreen> {
  bool _isSaving = false;

  void _startExperiment(Map<String, dynamic> template) {
    final manifest = CurriculumExperimentMapper.mapTemplateToManifest(template);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExperimentPlayerScreen(
          manifest: manifest,
          executionPayload: template,
        ),
      ),
    );
  }

  void _openDetails(Map<String, dynamic> template) {
    final manifest = CurriculumExperimentMapper.mapTemplateToManifest(template);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExperimentDetailsScreen(
          manifest: manifest,
          executionPayload: template,
        ),
      ),
    );
  }

  Future<void> _editTemplate(Map<String, dynamic> template) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final sceneData = template['scene'] as Map<String, dynamic>? ?? {};
      final templateName = sceneData['name'] ?? 'New Investigation';
      final draftName =
          '$templateName (Edit ${const Uuid().v4().substring(0, 4)})';

      final draftManager = BuilderDraftManager(
        SharedPreferencesBuilderDraftRepository(),
      );
      await draftManager.createDraft(draftName, template);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ExperimentBuilderScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Editable copy saved as "$draftName".')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not prepare editable copy: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = ExperimentTemplates.allTemplates;

    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Experiment Catalog'),
        backgroundColor: IDPColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: IDPColors.primary),
        titleTextStyle: IDPTypography.titleMedium.copyWith(color: IDPColors.textPrimary),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: IDPColors.primary))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _ExperimentCatalogCard(
                  template: template,
                  onStart: () => _startExperiment(template),
                  onDetails: () => _openDetails(template),
                  onEdit: () => _editTemplate(template),
                );
              },
            ),
    );
  }
}

class _ExperimentCatalogCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final VoidCallback onStart;
  final VoidCallback onDetails;
  final VoidCallback onEdit;

  const _ExperimentCatalogCard({
    required this.template,
    required this.onStart,
    required this.onDetails,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = template['metadata'] as Map<String, dynamic>? ?? {};
    final scene = template['scene'] as Map<String, dynamic>? ?? {};

    final category = metadata['category'] ?? 'General';
    final difficulty = metadata['difficulty'] ?? 'Medium';
    final name = scene['name'] ?? 'Untitled Experiment';
    final estimatedTime = metadata['estimatedTime'] ?? '15 mins';

    return GestureDetector(
      onTap: onDetails,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: IDPColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: IDPColors.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder area
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: IDPColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  Icons.science_outlined,
                  size: 48,
                  color: IDPColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toString().toUpperCase(),
                    style: IDPTypography.labelSmall.copyWith(
                      color: IDPColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name.toString(),
                    style: IDPTypography.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${estimatedTime.toString()} • Difficulty: ${difficulty.toString()}',
                    style: IDPTypography.bodySmall.copyWith(
                      color: IDPColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onEdit,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: IDPColors.primary),
                          ),
                          child: const Text('EDIT'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: onStart,
                          style: FilledButton.styleFrom(
                            backgroundColor: IDPColors.primary,
                          ),
                          child: const Text('START'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
