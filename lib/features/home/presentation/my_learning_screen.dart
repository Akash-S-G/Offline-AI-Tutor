import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../course/data/local/curriculum_repository.dart';
import '../../course/domain/curriculum_models.dart';
import '../../assessment/data/local/quiz_result_repository.dart';
import '../../onboarding/presentation/grade_sync_screen.dart';
import 'subject_screen.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key});

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  final CurriculumRepository _curriculumRepo = CurriculumRepository();
  final QuizResultRepository _quizRepo = QuizResultRepository();
  
  bool _loading = true;
  int _selectedGrade = 8;
  List<CurriculumSubject> _subjects = [];
  Map<String, int> _chapterQuizAttempts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final grade = prefs.getInt('selected_grade') ?? 8;
    
    // Fetch all quiz results to compute progress
    final allResults = await _quizRepo.getAllResults();
    final Map<String, int> attemptsMap = {};
    for (final res in allResults) {
      attemptsMap[res.chapterId] = (attemptsMap[res.chapterId] ?? 0) + 1;
    }

    // Fetch curriculum
    final curriculum = await _curriculumRepo.getCurriculum();
    
    // Find the grade matching selected grade
    final matchedGrade = curriculum.firstWhere(
      (g) => g.grade == grade,
      orElse: () => CurriculumGrade(grade: grade, subjects: []),
    );

    if (mounted) {
      setState(() {
        _selectedGrade = grade;
        _subjects = matchedGrade.subjects;
        _chapterQuizAttempts = attemptsMap;
        _loading = false;
      });
    }
  }

  double _getSubjectProgress(CurriculumSubject subject) {
    if (subject.chapters.isEmpty) return 0.0;
    int attempted = 0;
    for (final chapter in subject.chapters) {
      if (_chapterQuizAttempts.containsKey(chapter.packId)) {
        attempted++;
      }
    }
    return attempted / subject.chapters.length;
  }

  Color _getSubjectColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) {
      return const Color(0xFF6366F1); // Indigo
    } else if (lower.contains('science')) {
      return const Color(0xFF0D9488); // Teal
    } else if (lower.contains('english')) {
      return const Color(0xFFD97706); // Amber
    } else if (lower.contains('kannada')) {
      return const Color(0xFFDC2626); // Red
    } else if (lower.contains('social')) {
      return const Color(0xFF8B5CF6); // Violet
    }
    return const Color(0xFF4B5563); // Slate/Grey
  }

  IconData _getSubjectIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) {
      return Icons.calculate_rounded;
    } else if (lower.contains('science')) {
      return Icons.science_rounded;
    } else if (lower.contains('english')) {
      return Icons.translate_rounded;
    } else if (lower.contains('kannada')) {
      return Icons.menu_book_rounded;
    } else if (lower.contains('social')) {
      return Icons.public_rounded;
    }
    return Icons.school_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0B6E4F),
        ),
      );
    }

    if (_subjects.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF0B6E4F),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          ..._subjects.map((subj) => _buildSubjectCard(subj)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B6E4F), Color(0xFF08523B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B6E4F).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grade $_selectedGrade',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Offline Mode',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'My Learning Journey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Study textbooks, take interactive quizzes, and ask the AI Tutor questions fully offline.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(CurriculumSubject subject) {
    final progress = _getSubjectProgress(subject);
    final themeColor = _getSubjectColor(subject.name);
    final icon = _getSubjectIcon(subject.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SubjectScreen(subject: subject),
              ),
            ).then((_) => _loadData()); // Reload on return to catch updated quiz scores
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: themeColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subject.chapters.length} ${subject.chapters.length == 1 ? 'Chapter' : 'Chapters'}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF94A3B8),
                  size: 16,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.school_outlined,
            size: 80,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 20),
          Text(
            'No Content for Grade $_selectedGrade',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t installed any offline content packs for Grade $_selectedGrade yet. Download content to start learning offline.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GradeSyncScreen(grade: _selectedGrade),
                ),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.download_rounded),
            label: Text('Install Grade $_selectedGrade Content'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B6E4F),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
