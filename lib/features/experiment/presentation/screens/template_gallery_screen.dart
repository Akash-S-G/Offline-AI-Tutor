import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Explore Experiments'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
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
    final grade = metadata['grade'] ?? 'General';
    final subject = metadata['subject'] ?? 'Science';
    final estimatedTime = metadata['estimatedTime'] ?? '15 mins';
    final name = scene['name'] ?? 'Untitled Experiment';
    final description =
        scene['description'] ?? 'Investigate, observe, and record evidence.';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: Color(0xFF10B981),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _MetaBadge(Icons.category_rounded, category.toString()),
                _MetaBadge(Icons.school_rounded, grade.toString()),
                _MetaBadge(Icons.book_rounded, subject.toString()),
                _MetaBadge(Icons.schedule_rounded, estimatedTime.toString()),
                _MetaBadge(Icons.leaderboard_rounded, difficulty.toString()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.info_outline_rounded),
                    label: const Text('Details'),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Edit Template'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaBadge(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF475569)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
