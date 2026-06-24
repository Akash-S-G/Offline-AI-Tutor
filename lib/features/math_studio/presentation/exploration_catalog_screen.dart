import 'package:flutter/material.dart';

import '../../../core/theme/idp_colors.dart';
import '../domain/challenge.dart';
import 'functions_workspace_screen.dart';
import 'geometry_workspace_screen.dart';
import 'statistics_workspace_screen.dart';

class ExplorationCatalogScreen extends StatelessWidget {
  const ExplorationCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Guided Explorations'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Discover Mathematics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: IDPColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose an exploration to manipulate variables and observe mathematical behaviors.',
              style: TextStyle(
                color: IDPColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildCatalogSection('Algebra & Functions', [
              _CatalogItem(
                title: 'Linear Functions',
                description: 'Explore slope and y-intercept in y = mx + c.',
                icon: Icons.show_chart_rounded,
                color: const Color(0xFFD97706),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FunctionLabScreen(
                        initialFormula: 'm*x + c',
                        discoveryPrompt:
                            'Explore how changing the slope (m) and y-intercept (c) affects the line.',
                      ),
                    ),
                  );
                },
              ),
              _CatalogItem(
                title: 'Quadratic Functions',
                description: 'See how a, b, and c reshape a parabola.',
                icon: Icons.stacked_line_chart_rounded,
                color: const Color(0xFFD97706),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FunctionLabScreen(
                        initialFormula: 'a*x^2 + b*x + c',
                        discoveryPrompt:
                            'Discover how changing a, b, and c affects the shape and position of the parabola.',
                      ),
                    ),
                  );
                },
              ),
            ]),
            _buildCatalogSection('Geometry', [
              _CatalogItem(
                title: 'Circle Area & Circumference',
                description: 'See how changing the radius affects the area.',
                icon: Icons.radio_button_unchecked_rounded,
                color: const Color(0xFF0D9488),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GeometryWorkspaceScreen(
                        initialShape: GeometryShape.circle,
                        discoveryPrompt:
                            'Observe how the area changes as you drag the radius.',
                      ),
                    ),
                  );
                },
              ),
              _CatalogItem(
                title: 'Pythagorean Theorem',
                description:
                    'Explore the relationship between a right triangle’s sides.',
                icon: Icons.change_history_rounded,
                color: const Color(0xFF0D9488),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GeometryWorkspaceScreen(
                        initialShape: GeometryShape.triangle,
                        discoveryPrompt:
                            'Drag the corners to form a right-angled triangle. What do you notice about the sides?',
                      ),
                    ),
                  );
                },
              ),
            ]),
            _buildCatalogSection('Statistics', [
              _CatalogItem(
                title: 'Mean vs Median',
                description: 'Understand how outliers affect averages.',
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
            ]),
            _buildCatalogSection('Interactive Challenges', [
              _CatalogItem(
                title: 'Function Challenge: Downward Parabola',
                description: 'Create a parabola that opens downward.',
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FunctionLabScreen(
                        initialFormula: 'a*x^2 + b*x + c',
                        challenge: ChallengeEngine.functionChallenges[0],
                      ),
                    ),
                  );
                },
              ),
              _CatalogItem(
                title: 'Geometry Challenge: Area 50',
                description: 'Construct a shape with an area of roughly 50.',
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GeometryWorkspaceScreen(
                        initialShape: GeometryShape.polygon,
                        challenge: ChallengeEngine.geometryChallenges[0],
                      ),
                    ),
                  );
                },
              ),
              _CatalogItem(
                title: 'Statistics Challenge: Mean 20',
                description: 'Create a dataset whose mean is exactly 20.',
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatisticsLabScreen(
                        challenge: ChallengeEngine.statisticsChallenges[0],
                      ),
                    ),
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: IDPColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: e),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _CatalogItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CatalogItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: IDPColors.textSecondary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
