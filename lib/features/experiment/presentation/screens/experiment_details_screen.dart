// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../builder/screens/experiment_builder_screen.dart';
import '../../builder/storage/builder_draft_manager.dart';
import '../../builder/storage/builder_draft_repository.dart';
import '../../domain/models/experiment_models.dart';
import 'experiment_player_screen.dart';

class ExperimentDetailsScreen extends StatefulWidget {
  final ExperimentManifest manifest;
  final Map<String, dynamic>? executionPayload;

  const ExperimentDetailsScreen({
    super.key,
    required this.manifest,
    this.executionPayload,
  });

  @override
  State<ExperimentDetailsScreen> createState() =>
      _ExperimentDetailsScreenState();
}

class _ExperimentDetailsScreenState extends State<ExperimentDetailsScreen> {
  bool _isPreparingEdit = false;

  @override
  void initState() {
    super.initState();
    print('[EXPERIMENT_UI] DETAILS_LOAD');
  }

  void _startExperiment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExperimentPlayerScreen(
          manifest: widget.manifest,
          executionPayload: widget.executionPayload,
        ),
      ),
    );
  }

  Future<void> _editTemplate() async {
    final payload = widget.executionPayload;
    if (payload == null) return;

    setState(() {
      _isPreparingEdit = true;
    });

    try {
      final sceneData = payload['scene'] as Map<String, dynamic>? ?? {};
      final templateName = sceneData['name'] ?? widget.manifest.title;
      final draftName =
          '$templateName (Edit ${const Uuid().v4().substring(0, 4)})';

      final draftManager = BuilderDraftManager(
        SharedPreferencesBuilderDraftRepository(),
      );
      await draftManager.createDraft(draftName, payload);

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
          _isPreparingEdit = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final learningOutcomes = _learningOutcomes();
    final skills = _skills();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Experiment Details'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.manifest.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(widget.manifest.subject),
                      _InfoChip(widget.manifest.difficulty.name),
                      _InfoChip(
                        '${widget.manifest.estimatedDurationMinutes} min',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.manifest.description,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DetailSection(
              title: 'What You Will Learn',
              children: learningOutcomes
                  .map((outcome) => _BulletText(text: outcome))
                  .toList(),
            ),
            const SizedBox(height: 14),
            _DetailSection(
              title: 'What You Will Investigate',
              children: [
                _BulletText(
                  text:
                      'Change experiment parameters and observe how the result responds.',
                ),
                _BulletText(
                  text:
                      'Record measurements, compare trials, and explain the pattern you see.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailSection(
              title: 'Skills',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((skill) => _SkillChip(skill)).toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _startExperiment,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'START EXPERIMENT',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
              ),
            ),
            if (widget.executionPayload != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isPreparingEdit ? null : _editTemplate,
                  icon: _isPreparingEdit
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.tune_rounded),
                  label: const Text('EDIT TEMPLATE'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _learningOutcomes() {
    final payload = widget.executionPayload;
    final scene = payload?['scene'] as Map<String, dynamic>?;
    final values = scene?['learningOutcomes'];
    if (values is List && values.isNotEmpty) {
      return values.map((value) => value.toString()).toList();
    }
    return [
      'Identify how changing one condition affects the experiment.',
      'Use observations and measurements as evidence.',
      'Write a conclusion that connects cause and effect.',
    ];
  }

  List<String> _skills() {
    final values = <String>{
      widget.manifest.subject,
      'Observation',
      'Measurement',
      'Comparison',
      'Conclusion',
    };
    if (widget.manifest.supportsSensorExecution) {
      values.add('Sensor data');
    }
    return values.toList();
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;

  const _BulletText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF475569), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: const Color(0xFFEFF6FF),
      side: const BorderSide(color: Color(0xFFBFDBFE)),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;

  const _SkillChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.school_rounded, size: 16),
      visualDensity: VisualDensity.compact,
    );
  }
}
