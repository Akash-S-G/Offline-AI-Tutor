import 'package:flutter/material.dart';

import '../../course/domain/curriculum_models.dart';
import '../../course/domain/course_tree.dart';
import '../../chat/presentation/chapter_chat_screen.dart';
import 'chapter_reader_screen.dart';
import 'quiz_player_screen.dart';
import 'chapter_summary_screen.dart';

class ChapterDashboardScreen extends StatelessWidget {
  const ChapterDashboardScreen({
    required this.chapter,
    required this.subject,
    super.key,
  });

  final CurriculumChapter chapter;
  final CurriculumSubject subject;

  Color _getSubjectColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) {
      return const Color(0xFF6366F1);
    } else if (lower.contains('science')) {
      return const Color(0xFF0D9488);
    } else if (lower.contains('english')) {
      return const Color(0xFFD97706);
    } else if (lower.contains('kannada')) {
      return const Color(0xFFDC2626);
    } else if (lower.contains('social')) {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFF4B5563);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getSubjectColor(subject.name);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(subject.name),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chapter Title Header
            Text(
              chapter.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Grade ${chapter.grade} • ${chapter.language.toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Summary Card
            _buildSummaryCard(context, themeColor),
            const SizedBox(height: 24),

            // Action Grid
            const Text(
              'Learning Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context: context,
              title: 'Read Textbook',
              subtitle: 'Study textbook content & examples offline',
              icon: Icons.menu_book_rounded,
              colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChapterReaderScreen(chapter: chapter),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context: context,
              title: 'Practice Quiz',
              subtitle: 'Test your understanding with practice questions',
              icon: Icons.assignment_turned_in_rounded,
              colors: [const Color(0xFF10B981), const Color(0xFF047857)],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizPlayerScreen(chapter: chapter),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context: context,
              title: 'Summarize & Flashcards',
              subtitle: 'Review key terms and swipe study cards',
              icon: Icons.style_rounded,
              colors: [const Color(0xFFF59E0B), const Color(0xFFB45309)],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChapterSummaryScreen(chapter: chapter),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context: context,
              title: 'Ask AI Tutor',
              subtitle: 'Ask helper questions using offline local RAG',
              icon: Icons.chat_bubble_rounded,
              colors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
              onTap: () {
                // Map to legacy models to pass to ChapterChatScreen
                final legacyCourse = Course(
                  id: 'grade_${chapter.grade}',
                  name: 'Grade ${chapter.grade}',
                );
                final legacySubject = Subject(
                  id: 'sub_${subject.name.toLowerCase()}',
                  courseId: legacyCourse.id,
                  name: subject.name,
                );
                final legacyChapter = Chapter(
                  id: chapter.packId,
                  subjectId: legacySubject.id,
                  title: chapter.title,
                  summary: chapter.summary,
                );

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChapterChatScreen(
                      course: legacyCourse,
                      subject: legacySubject,
                      chapter: legacyChapter,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Color themeColor) {
    final hasSummary = chapter.summary.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: themeColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Chapter Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasSummary 
                ? chapter.summary 
                : 'Study this chapter to master core concepts, definition rules, and practice application questions.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
