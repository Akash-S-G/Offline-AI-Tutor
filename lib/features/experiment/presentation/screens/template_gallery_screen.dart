import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../builder/templates/experiment_templates.dart';
import '../../builder/storage/builder_draft_manager.dart';
import '../../builder/storage/builder_draft_repository.dart';
import '../../builder/screens/experiment_builder_screen.dart';

class TemplateGalleryScreen extends StatefulWidget {
  const TemplateGalleryScreen({super.key});

  @override
  State<TemplateGalleryScreen> createState() => _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends State<TemplateGalleryScreen> {
  bool _isSaving = false;

  Future<void> _useTemplate(Map<String, dynamic> template) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final sceneData = template['scene'] as Map<String, dynamic>? ?? {};
      final templateName = sceneData['name'] ?? 'New Template';
      final draftName = '$templateName (Draft ${const Uuid().v4().substring(0, 4)})';

      final draftManager = BuilderDraftManager(SharedPreferencesBuilderDraftRepository());
      await draftManager.createDraft(draftName, template);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ExperimentBuilderScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template saved as "$draftName". Open it from the Drafts tab.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to use template: $e')),
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
        title: const Text('Template Gallery'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final tpl = templates[index];
                final metadata = tpl['metadata'] as Map<String, dynamic>? ?? {};
                final scene = tpl['scene'] as Map<String, dynamic>? ?? {};
                
                final category = metadata['category'] ?? 'General';
                final difficulty = metadata['difficulty'] ?? 'Medium';
                final grade = metadata['grade'] ?? 'General';
                final subject = metadata['subject'] ?? 'Science';
                final estimatedTime = metadata['estimatedTime'] ?? '15 mins';

                final name = scene['name'] ?? 'Untitled Template';
                final description = scene['description'] ?? 'No description provided.';
                final tags = List<String>.from(scene['tags'] ?? []);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category.toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.auto_awesome_motion_rounded, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildMetaBadge(Icons.school_rounded, grade, const Color(0xFF3B82F6)),
                            _buildMetaBadge(Icons.book_rounded, subject, const Color(0xFFF59E0B)),
                            _buildMetaBadge(Icons.schedule_rounded, estimatedTime, const Color(0xFF8B5CF6)),
                            _buildMetaBadge(Icons.leaderboard_rounded, difficulty, const Color(0xFFEF4444)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags.map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _useTemplate(tpl),
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Use Template'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
