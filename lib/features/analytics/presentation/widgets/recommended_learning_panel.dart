import 'package:flutter/material.dart';
import '../../domain/learning_profile_models.dart';

class RecommendedLearningPanel extends StatelessWidget {
  final List<LearningRecommendation> recommendations;

  const RecommendedLearningPanel({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Recommended for You',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return _buildRecommendationCard(context, rec);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(BuildContext context, LearningRecommendation rec) {
    IconData icon;
    Color color;

    switch (rec.actionRoute) {
      case 'quiz':
        icon = Icons.assignment_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'experiment':
        icon = Icons.science_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case 'chapter':
      default:
        icon = Icons.menu_book_rounded;
        color = const Color(0xFF10B981);
        break;
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Navigating to ${rec.title}...')),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rec.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    rec.description,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Start Now', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFF3B82F6), size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
