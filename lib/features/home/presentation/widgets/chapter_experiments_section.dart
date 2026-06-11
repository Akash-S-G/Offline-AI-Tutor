import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../course/domain/curriculum_models.dart';
import '../../../course/domain/curriculum_experiment_mapper.dart';
import '../../../../features/experiment/presentation/screens/experiment_details_screen.dart';
import '../../../../features/experiment/builder/screens/experiment_builder_screen.dart';
import '../../../../features/experiment/builder/storage/builder_draft_manager.dart';
import '../../../../features/experiment/builder/storage/builder_draft_repository.dart';

class ChapterExperimentsSection extends StatelessWidget {
  final CurriculumChapter chapter;
  final CurriculumSubject subject;

  const ChapterExperimentsSection({
    super.key,
    required this.chapter,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final templates = CurriculumExperimentMapper.getExperimentsForChapter(
      chapter,
      subject,
    );

    if (templates.isEmpty) {
      return const SizedBox.shrink(); // Hide if no related experiments
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Related Experiments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        ...templates.map((tpl) => _buildExperimentCard(context, tpl)),
      ],
    );
  }

  Widget _buildExperimentCard(
    BuildContext context,
    Map<String, dynamic> template,
  ) {
    final metadata = template['metadata'] as Map<String, dynamic>? ?? {};
    final scene = template['scene'] as Map<String, dynamic>? ?? {};

    final name = scene['name'] ?? 'Untitled Experiment';
    final description = scene['description'] ?? '';
    final difficulty = metadata['difficulty'] ?? 'Medium';
    final estimatedTime = metadata['estimatedTime'] ?? '15 mins';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildBadge(
                  Icons.schedule_rounded,
                  estimatedTime,
                  const Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 12),
                _buildBadge(
                  Icons.leaderboard_rounded,
                  difficulty,
                  const Color(0xFFEF4444),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleCustomize(context, template),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Template'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _handleLaunch(context, template),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _handleLaunch(BuildContext context, Map<String, dynamic> template) {
    final manifest = CurriculumExperimentMapper.mapTemplateToManifest(
      template,
      chapterId: chapter.packId,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExperimentDetailsScreen(
          manifest: manifest,
          executionPayload: template,
        ),
      ),
    );
  }

  Future<void> _handleCustomize(
    BuildContext context,
    Map<String, dynamic> template,
  ) async {
    try {
      final sceneData = template['scene'] as Map<String, dynamic>? ?? {};
      final templateName = sceneData['name'] ?? 'Customized Experiment';
      final draftName =
          '$templateName (Draft ${const Uuid().v4().substring(0, 4)})';

      final draftManager = BuilderDraftManager(
        SharedPreferencesBuilderDraftRepository(),
      );
      await draftManager.createDraft(draftName, template);

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ExperimentBuilderScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to customize experiment: $e')),
        );
      }
    }
  }
}
