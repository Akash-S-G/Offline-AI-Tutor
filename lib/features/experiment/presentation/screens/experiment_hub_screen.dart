import 'package:flutter/material.dart';

import 'experiment_catalog_screen.dart';
import 'experiment_history_screen.dart';
import 'lab_reports_screen.dart';
import 'template_certification_screen.dart';
import '../../builder/screens/experiment_builder_screen.dart';

class ExperimentHubScreen extends StatelessWidget {
  const ExperimentHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Virtual Laboratory'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<_AdvancedLabAction>(
            tooltip: 'Advanced',
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _HeroPanel(
              onExplore: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExperimentCatalogScreen(),
                ),
              ),
              onContinue: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const ExperimentHistoryScreen(studentId: 'offline_user'),
                ),
              ),
              onReports: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LabReportsScreen()),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Search Experiments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              readOnly: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExperimentCatalogScreen(),
                ),
              ),
              decoration: InputDecoration(
                hintText: 'Search by topic, skill, or subject',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Featured Experiments',
              actionLabel: 'View all',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExperimentCatalogScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _FeaturedExperiments(
              onOpenCatalog: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExperimentCatalogScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Explore by Subject',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _SubjectChip(label: 'Physics', icon: Icons.speed_rounded),
                _SubjectChip(label: 'Chemistry', icon: Icons.science_rounded),
                _SubjectChip(label: 'Biology', icon: Icons.eco_rounded),
                _SubjectChip(
                  label: 'Mathematics',
                  icon: Icons.functions_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Recent Reports',
              actionLabel: 'Open',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LabReportsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _RecentReportCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LabReportsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AdvancedLabAction { creator, history, verification }

class _HeroPanel extends StatelessWidget {
  final VoidCallback onExplore;
  final VoidCallback onContinue;
  final VoidCallback onReports;

  const _HeroPanel({
    required this.onExplore,
    required this.onContinue,
    required this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VIRTUAL LABORATORY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose an investigation, run the experiment, record evidence, and build your lab report.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 15),
          ),
          const SizedBox(height: 20),
          _HeroAction(
            icon: Icons.play_arrow_rounded,
            label: 'Explore Experiments',
            color: const Color(0xFF10B981),
            onTap: onExplore,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroAction(
                  icon: Icons.restore_rounded,
                  label: 'Continue Investigation',
                  color: const Color(0xFF3B82F6),
                  onTap: onContinue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroAction(
                  icon: Icons.description_rounded,
                  label: 'My Lab Reports',
                  color: const Color(0xFFF59E0B),
                  onTap: onReports,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HeroAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label, textAlign: TextAlign.center),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _FeaturedExperiments extends StatelessWidget {
  final VoidCallback onOpenCatalog;

  const _FeaturedExperiments({required this.onOpenCatalog});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeaturedCard(
          title: 'Pendulum Motion',
          subtitle: 'Investigate how length changes the swing period.',
          icon: Icons.swap_vert_circle_rounded,
          color: const Color(0xFF3B82F6),
          onTap: onOpenCatalog,
        ),
        const SizedBox(height: 10),
        _FeaturedCard(
          title: 'Free Fall',
          subtitle: 'Measure height, velocity, and acceleration.',
          icon: Icons.south_rounded,
          color: const Color(0xFF10B981),
          onTap: onOpenCatalog,
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SubjectChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ExperimentCatalogScreen()),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    );
  }
}

class _RecentReportCard extends StatelessWidget {
  final VoidCallback onTap;

  const _RecentReportCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                color: Color(0xFF10B981),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Open completed investigations and exported lab reports.',
                  style: TextStyle(color: Color(0xFF475569)),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
