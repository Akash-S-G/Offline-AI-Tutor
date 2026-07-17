import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../course/data/local/curriculum_repository.dart';
import '../../course/domain/curriculum_models.dart';
import '../../assessment/data/local/quiz_result_repository.dart';
import '../../analytics/application/learning_insights_service.dart';
import '../../analytics/domain/learning_profile_models.dart';
import '../../../core/widgets/idp_core_widgets.dart';
import '../../../core/widgets/idp_skeleton_loader.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/theme/idp_theme.dart';
import '../../analytics/presentation/widgets/recommended_learning_panel.dart';
import '../../analytics/presentation/screens/offline_learning_report_screen.dart';
import '../../onboarding/presentation/grade_sync_screen.dart';
import 'subject_screen.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({
    required this.languageCode,
    super.key,
  });

  final String languageCode;

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
  LearningProfile? _profile;

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

    // Fetch quiz results, insights service, and curriculum in parallel.
    final results = await Future.wait([
      _quizRepo.getAllResults(),
      LearningInsightsService.create(),
      _curriculumRepo.getCurriculum(languageCode: widget.languageCode),
    ]);

    final allResults = results[0] as List<dynamic>;
    final insights = results[1] as LearningInsightsService;
    final curriculum = results[2] as List<CurriculumGrade>;

    // Build attempts map
    final Map<String, int> attemptsMap = {};
    for (final res in allResults) {
      attemptsMap[res.chapterId] = (attemptsMap[res.chapterId] ?? 0) + 1;
    }

    // Generate profile (depends on insights being ready)
    final profile = await insights.generateProfile();

    // Find grade matching selected grade
    final matchedGrade = curriculum.firstWhere(
      (g) => g.grade == grade,
      orElse: () => CurriculumGrade(grade: grade, subjects: []),
    );

    if (mounted) {
      setState(() {
        _selectedGrade = grade;
        _subjects = matchedGrade.subjects;
        _chapterQuizAttempts = attemptsMap;
        _profile = profile;
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
      return ListView.separated(
        padding: const EdgeInsets.all(IDPSpacing.lg),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: IDPSpacing.md),
        itemBuilder: (_, index) => IDPSkeletonLoader(
          width: double.infinity,
          height: index == 0 ? 150 : 80,
          borderRadius: IDPRadius.lg,
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildHeader(),
          ),
          const SizedBox(height: 24),
          if (_profile != null) ...[
            _buildProgressDashboard(_profile!),
            const SizedBox(height: 24),
            RecommendedLearningPanel(recommendations: _profile!.recommendations),
            const SizedBox(height: 24),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: IDPSectionHeader(title: 'My Subjects'),
          ),
          const SizedBox(height: 12),
          ..._subjects.map((subj) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSubjectCard(subj),
          )),
        ],
      ),
    );
  }

  Widget _buildProgressDashboard(LearningProfile profile) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IDPSectionHeader(
            title: l10n.progressDashboard,
            trailing: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OfflineLearningReportScreen()),
                );
              },
              icon: const Icon(Icons.analytics_rounded, size: 16),
              label: Text(l10n.viewReport),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatBox(l10n.studyStreak, l10n.daysCount(profile.studyStreakDays), Icons.local_fire_department_rounded, const Color(0xFFF59E0B))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox(l10n.accuracy, '${profile.averageQuizAccuracy.toStringAsFixed(1)}%', Icons.check_circle_outline_rounded, const Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatBox(l10n.chapters, '${profile.completedChapters}', Icons.menu_book_rounded, const Color(0xFF3B82F6))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox(l10n.experiments, '${profile.experimentsCompleted}', Icons.science_rounded, const Color(0xFF8B5CF6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return IDPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: IDPSpacing.sm),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: IDPColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 12, color: IDPColors.textSecondary)),
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
                AppLocalizations.of(context)!.gradeLabel(_selectedGrade.toString()),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.offlineMode,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.myLearningJourney,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.myLearningJourneyDescription,
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
                        subject.chapters.length == 1
                            ? AppLocalizations.of(context)!.chapterCount(subject.chapters.length)
                            : AppLocalizations.of(context)!.chaptersCount(subject.chapters.length),
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
            AppLocalizations.of(context)!.noContentForGrade(_selectedGrade.toString()),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.noContentForGradeDescription(_selectedGrade.toString()),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GradeSyncScreen(
                    grade: _selectedGrade,
                    languageCode: widget.languageCode,
                  ),
                ),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.download_rounded),
            label: Text(AppLocalizations.of(context)!.installGradeContent(_selectedGrade.toString())),
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
