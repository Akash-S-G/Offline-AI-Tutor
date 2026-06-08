import 'package:flutter/material.dart';

import 'experiment_catalog_screen.dart';
import 'experiment_history_screen.dart';
import 'template_gallery_screen.dart';
import '../../builder/screens/experiment_builder_screen.dart';

class ExperimentHubScreen extends StatelessWidget {
  const ExperimentHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Experiment Studio'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildHubCard(
            context,
            title: 'Create Experiment',
            icon: Icons.science_rounded,
            color: const Color(0xFF3B82F6),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExperimentBuilderScreen()),
              );
            },
          ),
          _buildHubCard(
            context,
            title: 'Templates',
            icon: Icons.auto_awesome_motion_rounded,
            color: const Color(0xFF10B981),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TemplateGalleryScreen()),
              );
            },
          ),
          _buildHubCard(
            context,
            title: 'My Experiments',
            icon: Icons.folder_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () {
              // Navigates to Builder, where the Drafts tab allows them to manage their saved experiments
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExperimentBuilderScreen()),
              );
            },
          ),
          _buildHubCard(
            context,
            title: 'Experiment Catalog',
            icon: Icons.storefront_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExperimentCatalogScreen()),
              );
            },
          ),
          _buildHubCard(
            context,
            title: 'Experiment History',
            icon: Icons.history_rounded,
            color: const Color(0xFF64748B),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExperimentHistoryScreen(studentId: 'offline_user')),
              );
            },
          ),
          _buildHubCard(
            context,
            title: 'Import / Export',
            icon: Icons.import_export_rounded,
            color: const Color(0xFFEC4899),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Import/Export will be integrated with P2P module in next phase.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
