import 'package:flutter/material.dart';

import '../../../core/theme/idp_colors.dart';

import 'algebra_workspace_screen.dart';
import 'geometry_workspace_screen.dart';
import 'geometry_playground_screen.dart';
import 'functions_workspace_screen.dart';
import 'statistics_workspace_screen.dart';
import 'formula_playground_screen.dart';
import 'saved_explorations_screen.dart';
import 'exploration_catalog_screen.dart';

class MathStudioHomeScreen extends StatelessWidget {
  const MathStudioHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Math Studio'),
        backgroundColor: IDPColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final crossAxisExtent = isWide ? 240.0 : 180.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Explore Mathematics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: IDPColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Interactive workspaces for understanding mathematical concepts.',
                    style: TextStyle(
                      color: IDPColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: IDPColors.border),
                    ),
                    child: const Text(
                      'Choose a section. Each workspace keeps the concept, input controls, and visual output together so the page stays readable on phone screens.',
                      style: TextStyle(
                        color: IDPColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: (constraints.maxWidth / crossAxisExtent)
                        .floor()
                        .clamp(1, 4),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.25 : 0.88,
                    children: [
                      _buildCard(
                        title: 'Guided Explorations',
                        subtitle: 'Step-by-step math investigations',
                        icon: Icons.explore_rounded,
                        color: const Color(0xFF1E3A8A),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExplorationCatalogScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCard(
                        title: 'Algebra',
                        subtitle: 'Equations and solutions',
                        icon: Icons.calculate_rounded,
                        color: const Color(0xFF6366F1),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AlgebraWorkspaceScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCard(
                        title: 'Geometry',
                        subtitle: 'Shapes, area, perimeter',
                        icon: Icons.architecture_rounded,
                        color: const Color(0xFF0D9488),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GeometryWorkspaceScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCard(
                        title: 'Functions',
                        subtitle: 'Graphs and variables',
                        icon: Icons.show_chart_rounded,
                        color: const Color(0xFFD97706),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FunctionLabScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCard(
                        title: 'Statistics',
                        subtitle: 'Mean, median, mode',
                        icon: Icons.bar_chart_rounded,
                        color: const Color(0xFFDC2626),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StatisticsLabScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCard(
                        title: 'Playground',
                        subtitle: 'Formula visualizers',
                        icon: Icons.science_rounded,
                        color: const Color(0xFF8B5CF6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FormulaPlaygroundScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCard(
                        title: '2D Shape Playground',
                        subtitle: 'Interactive multi-shape canvas',
                        icon: Icons.dashboard_customize_rounded,
                        color: const Color(0xFF0F766E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GeometryPlaygroundScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCard(
                        title: 'Saved',
                        subtitle: 'Open stored workspaces',
                        icon: Icons.folder_special_rounded,
                        color: const Color(0xFF4B5563),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SavedExplorationsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 120;

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: color.withValues(alpha: 0.18)),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: EdgeInsets.all(isCompact ? 10 : 12),
              child: isCompact
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: IDPColors.textSecondary,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: IDPColors.textSecondary,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
