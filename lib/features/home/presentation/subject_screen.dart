import 'package:flutter/material.dart';

import '../../course/domain/curriculum_models.dart';
import '../../assessment/data/local/quiz_result_repository.dart';
import '../../assessment/domain/quiz_result.dart';
import 'chapter_dashboard_screen.dart';

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({
    required this.subject,
    super.key,
  });

  final CurriculumSubject subject;

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  final QuizResultRepository _quizRepo = QuizResultRepository();
  Map<String, QuizResult?> _chapterResults = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _loading = true;
    });

    final Map<String, QuizResult?> results = {};
    for (final chapter in widget.subject.chapters) {
      final res = await _quizRepo.getLatestChapterResult(chapter.packId);
      results[chapter.packId] = res;
    }

    if (mounted) {
      setState(() {
        _chapterResults = results;
        _loading = false;
      });
    }
  }

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
    final themeColor = _getSubjectColor(widget.subject.name);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0B6E4F)))
          : widget.subject.chapters.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemCount: widget.subject.chapters.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                        child: _buildSubjectAnalytics(themeColor),
                      );
                    }
                    final chapterIndex = index - 1;
                    final chapter = widget.subject.chapters[chapterIndex];
                    final result = _chapterResults[chapter.packId];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildChapterCard(chapter, result, chapterIndex + 1, themeColor),
                    );
                  },
                ),
    );
  }

  Widget _buildSubjectAnalytics(Color themeColor) {
    int totalQuizzes = 0;
    int correctAnswers = 0;
    int chaptersCompleted = 0;

    for (final result in _chapterResults.values) {
      if (result != null) {
        chaptersCompleted++;
        totalQuizzes += result.totalQuestions;
        correctAnswers += (result.score / 100 * result.totalQuestions).round();
      }
    }

    final double progress = widget.subject.chapters.isEmpty ? 0 : (chaptersCompleted / widget.subject.chapters.length) * 100;
    final double avgScore = totalQuizzes > 0 ? (correctAnswers / totalQuizzes) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subject Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn('Progress', '${progress.toStringAsFixed(0)}%', themeColor),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildStatColumn('Avg Score', '${avgScore.toStringAsFixed(1)}%', const Color(0xFFF59E0B)),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildStatColumn('Completed', '$chaptersCompleted/${widget.subject.chapters.length}', const Color(0xFF3B82F6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildChapterCard(CurriculumChapter chapter, QuizResult? result, int number, Color themeColor) {
    final isDone = result != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1.5,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChapterDashboardScreen(
                  chapter: chapter,
                  subject: widget.subject,
                ),
              ),
            ).then((_) => _loadResults()); // Refresh on back
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green.shade50 : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDone ? Colors.green.shade700 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDone 
                            ? 'Quiz Score: ${result.score}/${result.totalQuestions} (${result.percentage}%)'
                            : 'Textbook & materials available',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDone ? Colors.green.shade700 : const Color(0xFF64748B),
                          fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isDone)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 14,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Chapters Installed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No chapter packs were found for ${widget.subject.name}. Make sure they are installed successfully.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
