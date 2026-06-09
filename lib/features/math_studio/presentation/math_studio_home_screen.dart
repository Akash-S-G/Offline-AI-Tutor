import 'package:flutter/material.dart';

import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';

import 'algebra_workspace_screen.dart';
import 'geometry_workspace_screen.dart';
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
      body: SingleChildScrollView(
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
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCard(
                  context: context,
                  title: 'Guided Explorations',
                  icon: Icons.explore_rounded,
                  color: const Color(0xFF1E3A8A),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorationCatalogScreen()));
                  },
                ),
                _buildCard(
                  context: context,
                  title: 'Algebra',
                  icon: Icons.calculate_rounded,
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AlgebraWorkspaceScreen()));
                  },
                ),
                _buildCard(
                  context: context,
                  title: 'Geometry',
                  icon: Icons.architecture_rounded,
                  color: const Color(0xFF0D9488),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GeometryWorkspaceScreen()));
                  },
                ),
                _buildCard(
                  context: context,
                  title: 'Functions',
                  icon: Icons.show_chart_rounded,
                  color: const Color(0xFFD97706),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FunctionLabScreen()));
                  },
                ),
                _buildCard(
                  context: context,
                  title: 'Statistics',
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFFDC2626),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsLabScreen()));
                  },
                ),
                _buildCard(
                  context: context,
                  title: 'Playground',
                  icon: Icons.science_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FormulaPlaygroundScreen()));
                  },
                ),
                _buildCard(
                  context: context,
                  title: 'Saved',
                  icon: Icons.folder_special_rounded,
                  color: const Color(0xFF4B5563),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedExplorationsScreen()));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
