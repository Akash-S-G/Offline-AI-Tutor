import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../builder/screens/experiment_builder_screen.dart';
import '../../builder/storage/builder_draft_manager.dart';
import '../../builder/storage/builder_draft_repository.dart';
import '../../domain/models/experiment_models.dart';
import 'experiment_player_screen.dart';
import '../../../../core/theme/idp_colors.dart';
import '../../../../core/theme/idp_typography.dart';

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
    debugPrint('[EXPERIMENT_UI] DETAILS_LOAD');
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
    return Scaffold(
      backgroundColor: IDPColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: IDPColors.surface.withValues(alpha: 0.8),
      elevation: 0,
      iconTheme: const IconThemeData(color: IDPColors.primary),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        centerTitle: false,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Fake Image background
            Container(
              color: IDPColors.primaryContainer.withValues(alpha: 0.3),
              child: const Icon(Icons.science, size: 100, color: IDPColors.primary),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    IDPColors.background,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
            // Title and Badge
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: IDPColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.manifest.subject,
                      style: IDPTypography.labelMedium.copyWith(
                        color: IDPColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.manifest.title,
                    style: IDPTypography.headlineLarge.copyWith(
                      color: IDPColors.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.psychology),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layout for large screens could be rows, but we use wrap/column for responsive
          _buildActionButtons(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildTeacherNotes(),
          const SizedBox(height: 24),
          _buildLearningAndSkills(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [IDPColors.primary, IDPColors.primaryContainer],
              ),
              boxShadow: [
                BoxShadow(
                  color: IDPColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: _startExperiment,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, color: IDPColors.onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'START',
                      style: IDPTypography.titleMedium.copyWith(
                        color: IDPColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.executionPayload != null) ...[
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: IDPColors.primary, width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _isPreparingEdit ? null : _editTemplate,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isPreparingEdit)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: IDPColors.primary),
                        )
                      else
                        const Icon(Icons.tune, color: IDPColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'EDIT',
                        style: IDPTypography.titleMedium.copyWith(
                          color: IDPColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard(
          icon: Icons.schedule,
          label: 'Time',
          value: '${widget.manifest.estimatedDurationMinutes}m',
        ),
        _buildStatCard(
          icon: Icons.grade,
          label: 'Grade',
          value: '9', // Hardcoded as in Stitch for now, or could come from manifest
        ),
        _buildStatCard(
          icon: Icons.speed,
          label: 'Difficulty',
          value: widget.manifest.difficulty.name,
        ),
        _buildStatCard(
          icon: Icons.download,
          label: 'Offline',
          value: '45MB',
        ),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value}) {
    return Container(
      decoration: BoxDecoration(
        color: IDPColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IDPColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: IDPColors.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: IDPTypography.labelSmall.copyWith(
                  color: IDPColors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: IDPTypography.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherNotes() {
    return Container(
      decoration: BoxDecoration(
        color: IDPColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IDPColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: IDPColors.primary),
              const SizedBox(width: 8),
              Text(
                'Description & Notes',
                style: IDPTypography.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.manifest.description,
            style: IDPTypography.bodyMedium.copyWith(
              color: IDPColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: IDPColors.outlineVariant),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: IDPColors.primaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: IDPColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Curriculum Team',
                    style: IDPTypography.labelMedium,
                  ),
                  Text(
                    'Verified Expert Content',
                    style: IDPTypography.labelSmall.copyWith(
                      color: IDPColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearningAndSkills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLearningOutcomes(),
        const SizedBox(height: 24),
        _buildSkillsList(),
      ],
    );
  }

  Widget _buildLearningOutcomes() {
    final outcomes = _learningOutcomesList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: IDPColors.secondary),
              const SizedBox(width: 8),
              Text(
                'What You Will Learn',
                style: IDPTypography.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...outcomes.map((outcome) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: IDPColors.secondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        outcome,
                        style: IDPTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSkillsList() {
    final skills = _skillsList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IDPColors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IDPColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: IDPColors.primary),
              const SizedBox(width: 8),
              Text(
                'Skills & Categories',
                style: IDPTypography.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) => _buildSkillChip(skill)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IDPColors.outlineVariant),
      ),
      child: Text(
        label,
        style: IDPTypography.labelMedium,
      ),
    );
  }

  List<String> _learningOutcomesList() {
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

  List<String> _skillsList() {
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
