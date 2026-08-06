import 'package:flutter/material.dart';

import 'experiment_catalog_screen.dart';
import 'experiment_history_screen.dart';
import 'template_certification_screen.dart';
import '../../builder/screens/experiment_builder_screen.dart';
import '../../builder/templates/experiment_templates.dart';
import '../../../../core/theme/idp_colors.dart';
import '../../../../core/theme/idp_typography.dart';

class ExperimentHubScreen extends StatelessWidget {
  const ExperimentHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.surface,
      appBar: AppBar(
        title: Text('Virtual Laboratory', style: IDPTypography.titleLarge),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<_AdvancedLabAction>(
            tooltip: 'Advanced',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              switch (action) {
                case _AdvancedLabAction.creator:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExperimentBuilderScreen(),
                    ),
                  );
                case _AdvancedLabAction.history:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExperimentHistoryScreen(
                        studentId: 'offline_user',
                      ),
                    ),
                  );
                case _AdvancedLabAction.verification:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TemplateCertificationScreen(),
                    ),
                  );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AdvancedLabAction.creator,
                child: Text('Experiment Creator'),
              ),
              PopupMenuItem(
                value: _AdvancedLabAction.history,
                child: Text('Investigation History'),
              ),
              PopupMenuItem(
                value: _AdvancedLabAction.verification,
                child: Text('Template Verification'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Filter Chips
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(
                        icon: Icons.science_outlined,
                        label: 'Physics',
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  const ExperimentCatalogScreen()));
                        }),
                    const SizedBox(width: 8),
                    _FilterChip(
                        icon: Icons.biotech_outlined,
                        label: 'Chemistry',
                        onTap: () {}),
                    const SizedBox(width: 8),
                    _FilterChip(
                        icon: Icons.eco_outlined,
                        label: 'Biology',
                        onTap: () {}),
                    const SizedBox(width: 8),
                    _FilterChip(
                        icon: Icons.functions_outlined,
                        label: 'Math',
                        onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Continue Experiment
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Continue Experiment',
                            style: IDPTypography.titleMedium),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ExperimentHistoryScreen(
                                        studentId: 'offline_user')),
                          ),
                          child: Text(
                            'View History',
                            style: IDPTypography.labelMedium.copyWith(
                                color: IDPColors.primary,
                                decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ContinueExperimentCard(
                      title: 'Circuit Construction Kit',
                      progress: 0.65,
                      lastAccessed: '2 hours ago • Physics Lab 102',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const ExperimentHistoryScreen(
                                    studentId: 'offline_user')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recommended for You
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommended for You',
                        style: IDPTypography.titleMedium),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final templates = [
                          ExperimentTemplates.pendulum,
                          ExperimentTemplates.plantGrowth
                        ];
                        if (constraints.maxWidth > 600) {
                          return Row(
                            children: [
                              Expanded(
                                  child: _RecommendedCard(
                                      template: templates[0])),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _RecommendedCard(
                                      template: templates[1])),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _RecommendedCard(template: templates[0]),
                            const SizedBox(height: 16),
                            _RecommendedCard(template: templates[1]),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Subject Categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subject Categories',
                        style: IDPTypography.titleMedium),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
                          crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _SubjectCategoryCard(
                              title: 'Physics',
                              icon: Icons.science_outlined,
                              color: IDPColors.primary,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ExperimentCatalogScreen()),
                              ),
                            ),
                            _SubjectCategoryCard(
                              title: 'Chemistry',
                              icon: Icons.biotech_outlined,
                              color: IDPColors.secondary,
                              onTap: () {},
                            ),
                            _SubjectCategoryCard(
                              title: 'Biology',
                              icon: Icons.eco_outlined,
                              color: IDPColors.tertiary,
                              onTap: () {},
                            ),
                            _SubjectCategoryCard(
                              title: 'Math',
                              icon: Icons.functions_outlined,
                              color: IDPColors.error,
                              onTap: () {},
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AdvancedLabAction { creator, history, verification }

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: IDPColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: IDPColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: IDPTypography.labelMedium
                  .copyWith(color: IDPColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueExperimentCard extends StatelessWidget {
  final String title;
  final double progress;
  final String lastAccessed;
  final VoidCallback onTap;

  const _ContinueExperimentCard({
    required this.title,
    required this.progress,
    required this.lastAccessed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: IDPColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: IDPColors.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: IDPColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.electrical_services_outlined,
                  size: 32, color: IDPColors.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: IDPTypography.titleMedium
                              .copyWith(color: IDPColors.onSurface)),
                      Text('${(progress * 100).toInt()}% Complete',
                          style: IDPTypography.labelMedium
                              .copyWith(color: IDPColors.secondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: IDPColors.surfaceContainerHighest,
                    color: IDPColors.secondary,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(lastAccessed,
                      style: IDPTypography.bodySmall
                          .copyWith(color: IDPColors.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: IDPColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.play_arrow, color: IDPColors.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final Map<String, dynamic> template;

  const _RecommendedCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final metadata = template['metadata'] as Map<String, dynamic>;
    final scene = template['scene'] as Map<String, dynamic>;

    return Container(
      decoration: BoxDecoration(
        color: IDPColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IDPColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            color: IDPColors.surfaceContainerHighest,
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.science_outlined,
                      size: 48, color: IDPColors.primary.withValues(alpha: 0.5)),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: IDPColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.offline_pin,
                            size: 14, color: IDPColors.onSecondary),
                        const SizedBox(width: 4),
                        Text('Available Offline',
                            style: IDPTypography.bodySmall
                                .copyWith(color: IDPColors.onSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: IDPColors.tertiaryFixed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        metadata['grade'] ?? 'All Grades',
                        style: IDPTypography.bodySmall
                            .copyWith(color: IDPColors.onTertiaryFixedVariant),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 16, color: IDPColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          metadata['estimatedTime'] ?? '15 mins',
                          style: IDPTypography.bodySmall
                              .copyWith(color: IDPColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  scene['name'] ?? 'Experiment',
                  style: IDPTypography.titleMedium
                      .copyWith(color: IDPColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  scene['description'] ?? 'Explore the concepts.',
                  style: IDPTypography.bodyMedium
                      .copyWith(color: IDPColors.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ExperimentCatalogScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: IDPColors.primary,
                      side: const BorderSide(color: IDPColors.primary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Launch Lab', style: IDPTypography.labelLarge),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SubjectCategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: IDPColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(title, style: IDPTypography.labelLarge),
          ],
        ),
      ),
    );
  }
}
