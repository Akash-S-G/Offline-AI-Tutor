import 'package:flutter/material.dart';

import '../../domain/learning_profile_models.dart';
import '../../application/learning_insights_service.dart';

class OfflineLearningReportScreen extends StatefulWidget {
  const OfflineLearningReportScreen({super.key});

  @override
  State<OfflineLearningReportScreen> createState() => _OfflineLearningReportScreenState();
}

class _OfflineLearningReportScreenState extends State<OfflineLearningReportScreen> {
  LearningProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final insights = await LearningInsightsService.create();
    final profile = await insights.generateProfile();
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return const Scaffold(body: Center(child: Text('Failed to load report')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Learning Report'),
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Your Learning Insights', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Generated locally on your device', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Strengths'),
          const SizedBox(height: 12),
          if (_profile!.strengths.isEmpty)
            const Text('Keep learning to discover your strengths.', style: TextStyle(color: Color(0xFF64748B)))
          else
            ..._profile!.strengths.map((s) => _buildStrengthCard(s)),

          const SizedBox(height: 24),
          _buildSectionTitle('Areas for Improvement'),
          const SizedBox(height: 12),
          if (_profile!.weaknesses.isEmpty)
            const Text('No major weak areas detected. Great job!', style: TextStyle(color: Color(0xFF64748B)))
          else
            ..._profile!.weaknesses.map((w) => _buildWeaknessCard(w)),

          const SizedBox(height: 24),
          _buildSectionTitle('Unlocked Achievements'),
          const SizedBox(height: 12),
          if (_profile!.achievements.isEmpty)
            const Text('Complete chapters and quizzes to earn badges.', style: TextStyle(color: Color(0xFF64748B)))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _profile!.achievements.map((a) => _buildAchievementBadge(a)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)));
  }

  Widget _buildStrengthCard(StudentStrength strength) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
        title: Text(strength.topic, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(strength.description),
      ),
    );
  }

  Widget _buildWeaknessCard(StudentWeakness weakness) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_down_rounded, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text(weakness.topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text(weakness.description, style: const TextStyle(color: Color(0xFF475569))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(weakness.suggestedAction, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(StudentAchievement achievement) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 32),
          const SizedBox(height: 8),
          Text(achievement.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
