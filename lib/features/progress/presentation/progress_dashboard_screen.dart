import 'package:flutter/material.dart';

import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';
import '../../course/data/local/course_repository.dart';
import '../../course/domain/course_tree.dart';
import '../data/local/progress_repository.dart';
import '../../assessment/data/local/quiz_result_repository.dart';
import '../../assessment/domain/quiz_result.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({
    required this.courseRepository,
    required this.languageCode,
    super.key,
  });

  final CourseRepository courseRepository;
  final String languageCode;

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final ProgressRepository _progressRepository;
  late final QuizResultRepository _quizRepository;
  late final TabController _tabController;
  late Future<void> _loadFuture;

  List<ChapterWithProgress> _chaptersWithProgress = [];
  List<QuizResult> _allQuizResults = [];
  Map<String, String> _chapterTitleById = <String, String>{};
  Map<String, String> _chapterSubjectById = <String, String>{};

  @override
  void initState() {
    super.initState();
    _progressRepository = ProgressRepository();
    _quizRepository = QuizResultRepository();
    _tabController = TabController(length: 3, vsync: this);
    _loadFuture = _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final courses = await widget.courseRepository.getCourses(
      languageCode: widget.languageCode,
    );
    final chapters = <Chapter>[];
    final chapterTitleById = <String, String>{};
    final chapterSubjectById = <String, String>{};

    for (final course in courses) {
      final subjects = await widget.courseRepository.getSubjects(
        course.id,
        languageCode: widget.languageCode,
      );
      for (final subject in subjects) {
        final subjectChapters = await widget.courseRepository.getChapters(
          subject.id,
          languageCode: widget.languageCode,
        );
        chapters.addAll(subjectChapters);
        for (final chapter in subjectChapters) {
          chapterTitleById[chapter.id] = chapter.title;
          chapterSubjectById[chapter.id] = subject.name;
        }
      }
    }

    // Create chapter map
    final chapterMap = {for (final ch in chapters) ch.id: ch};

    // Load progress
    final progress = await _progressRepository.getAllChapterProgress();

    // Create combined list
    final combined = [
      for (final p in progress)
        if (chapterMap.containsKey(p.chapterId))
          ChapterWithProgress(
            chapter: chapterMap[p.chapterId]!,
            progress: p,
          )
    ];

    // Load quiz results
    final quizResults = await _quizRepository.getAllResults();

    setState(() {
      _chaptersWithProgress = combined;
      _allQuizResults = quizResults;
      _chapterTitleById = chapterTitleById;
      _chapterSubjectById = chapterSubjectById;
    });
  }

  String _formatLastActivity(int milliseconds) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  String _formatQuizDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  Color _masteryLevelColor(String level) {
    switch (level) {
      case 'Advanced':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Beginner':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Learning Progress', style: IDPTypography.titleMedium),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: IDPColors.primary,
          unselectedLabelColor: IDPColors.textSecondary,
          indicatorColor: IDPColors.primary,
          tabs: const [
            Tab(text: 'Chapter Progress'),
            Tab(text: 'Quiz History'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChapterProgressTab(),
          _buildQuizHistoryTab(),
          _buildLeaderboardTrendTab(),
        ],
      ),
    );
  }

  Widget _buildChapterProgressTab() {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: IDPColors.primary));
        }

        if (_chaptersWithProgress.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  size: 64,
                  color: IDPColors.textHint,
                ),
                const SizedBox(height: IDPSpacing.md),
                const Text(
                  'No progress yet',
                  style: IDPTypography.titleMedium,
                ),
                const SizedBox(height: IDPSpacing.xs),
                Text(
                  'Start tutoring to see your progress',
                  style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                ),
                const SizedBox(height: IDPSpacing.lg),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: IDPColors.primary),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          );
        }

        // Calculate overall mastery
        final averageMastery = _chaptersWithProgress.isEmpty
            ? 0.0
            : _chaptersWithProgress
                    .fold<double>(0, (sum, cwp) => sum + cwp.progress.masteryScore) /
                _chaptersWithProgress.length;

        return ListView(
          padding: const EdgeInsets.all(IDPSpacing.md),
          children: [
            // Overall summary card
            IDPCard(
              backgroundColor: IDPColors.primaryContainer.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IDPSectionHeader(
                    title: 'Overall Mastery',
                    subtitle: 'Average score across active chapters',
                  ),
                  const SizedBox(height: IDPSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${averageMastery.toStringAsFixed(0)}%',
                              style: IDPTypography.headlineLarge.copyWith(color: IDPColors.primary),
                            ),
                            const SizedBox(height: IDPSpacing.xs / 2),
                            Text(
                              '${_chaptersWithProgress.length} chapters tracked',
                              style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(IDPRadius.sm),
                          child: LinearProgressIndicator(
                            value: averageMastery / 100,
                            minHeight: 12,
                            backgroundColor: IDPColors.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              averageMastery >= 80
                                  ? IDPColors.success
                                  : averageMastery >= 50
                                      ? IDPColors.warning
                                      : IDPColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: IDPSpacing.lg),
            const IDPSectionHeader(title: 'Chapter Breakdown'),
            const SizedBox(height: IDPSpacing.sm),
            // Per-chapter cards
            ...List.generate(
              _chaptersWithProgress.length,
              (index) {
                final cwp = _chaptersWithProgress[index];
                final color = _masteryLevelColor(cwp.progress.masteryLevel);

                return Padding(
                  padding: const EdgeInsets.only(bottom: IDPSpacing.sm),
                  child: IDPCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cwp.chapter.title,
                                    style: IDPTypography.titleSmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: IDPSpacing.xs / 2),
                                  Text(
                                    'Active ${_formatLastActivity(cwp.progress.lastActivityAt)}',
                                    style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: IDPSpacing.sm,
                                vertical: IDPSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(IDPRadius.sm),
                              ),
                              child: Text(
                                cwp.progress.masteryLevel,
                                style: IDPTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: IDPSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(IDPRadius.sm),
                          child: LinearProgressIndicator(
                            value: cwp.progress.masteryScore / 100,
                            minHeight: 8,
                            backgroundColor: IDPColors.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: IDPSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${cwp.progress.masteryScore.toStringAsFixed(0)}%',
                              style: IDPTypography.titleSmall,
                            ),
                            Row(
                              children: [
                                const Icon(Icons.question_answer_rounded, size: 14, color: IDPColors.textSecondary),
                                const SizedBox(width: IDPSpacing.xs / 2),
                                Text('${cwp.progress.questionsAsked} Q', style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary)),
                                const SizedBox(width: IDPSpacing.sm),
                                const Icon(Icons.chat_rounded, size: 14, color: IDPColors.textSecondary),
                                const SizedBox(width: IDPSpacing.xs / 2),
                                Text('${cwp.progress.totalMessages} msgs', style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuizHistoryTab() {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: IDPColors.primary));
        }

        if (_allQuizResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.quiz_rounded,
                  size: 64,
                  color: IDPColors.textHint,
                ),
                const SizedBox(height: IDPSpacing.md),
                const Text(
                  'No quizzes attempted yet',
                  style: IDPTypography.titleMedium,
                ),
                const SizedBox(height: IDPSpacing.xs),
                Text(
                  'Take quizzes from the Learning Materials',
                  style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(IDPSpacing.md),
          children: [
            const IDPSectionHeader(title: 'Recent Quiz Attempts'),
            const SizedBox(height: IDPSpacing.sm),
            ..._allQuizResults.take(20).map((result) {
              final performanceColor = result.percentage >= 80
                  ? IDPColors.success
                  : result.percentage >= 60
                      ? IDPColors.warning
                      : IDPColors.error;

              return Padding(
                padding: const EdgeInsets.only(bottom: IDPSpacing.sm),
                child: IDPCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chapter: ${result.chapterId}',
                                  style: IDPTypography.titleSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: IDPSpacing.xs / 2),
                                Text(
                                  _formatQuizDate(result.attemptedAt),
                                  style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: IDPSpacing.sm,
                              vertical: IDPSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: performanceColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(IDPRadius.sm),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${result.percentage}%',
                                  style: IDPTypography.titleMedium.copyWith(color: performanceColor),
                                ),
                                Text(
                                  result.performanceLabel,
                                  style: IDPTypography.labelSmall.copyWith(color: performanceColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: IDPSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: IDPColors.textSecondary),
                          const SizedBox(width: IDPSpacing.xs),
                          Text('${result.score}/${result.totalQuestions} correct', style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary)),
                          const SizedBox(width: IDPSpacing.md),
                          Icon(
                            result.passed ? Icons.thumb_up_rounded : Icons.info_rounded,
                            size: 14,
                            color: performanceColor,
                          ),
                          const SizedBox(width: IDPSpacing.xs),
                          Text(
                            result.passed ? 'Passed' : 'Needs Work',
                            style: IDPTypography.bodySmall.copyWith(color: performanceColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardTrendTab() {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: IDPColors.primary));
        }

        if (_allQuizResults.isEmpty) {
          return Center(
            child: Text('Take quizzes to unlock leaderboard and trend analytics.', style: IDPTypography.bodyMedium.copyWith(color: IDPColors.textSecondary)),
          );
        }

        final chapterGrouped = <String, List<QuizResult>>{};
        for (final result in _allQuizResults) {
          chapterGrouped.putIfAbsent(result.chapterId, () => <QuizResult>[]).add(result);
        }

        final chapterLeaders = chapterGrouped.entries
            .map((entry) {
              final attempts = entry.value;
              final average = attempts
                      .map((e) => e.percentage)
                      .fold<int>(0, (a, b) => a + b) /
                  attempts.length;
              final best = attempts
                  .map((e) => e.percentage)
                  .fold<int>(0, (a, b) => a > b ? a : b);
              return _ChapterLeader(
                chapterId: entry.key,
                chapterTitle: _chapterTitleById[entry.key] ?? entry.key,
                attemptCount: attempts.length,
                averageScore: average,
                bestScore: best,
              );
            })
            .toList()
          ..sort((a, b) => b.averageScore.compareTo(a.averageScore));

        final subjectGrouped = <String, List<QuizResult>>{};
        for (final result in _allQuizResults) {
          final subject = _chapterSubjectById[result.chapterId] ?? 'Unknown Subject';
          subjectGrouped.putIfAbsent(subject, () => <QuizResult>[]).add(result);
        }

        final subjectTrends = subjectGrouped.entries
            .map((entry) {
              final attempts = [...entry.value]
                ..sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
              final percentages = attempts.map((e) => e.percentage.toDouble()).toList();
              final average = percentages.isEmpty
                  ? 0.0
                  : percentages.reduce((a, b) => a + b) / percentages.length;

              final recent = percentages.isEmpty
                  ? 0.0
                  : percentages
                          .skip(percentages.length > 3 ? percentages.length - 3 : 0)
                          .reduce((a, b) => a + b) /
                      (percentages.length >= 3 ? 3 : percentages.length);

              final baselineSlice = percentages.length > 3
                  ? percentages.take(percentages.length - 3).toList()
                  : percentages;
              final baseline = baselineSlice.isEmpty
                  ? recent
                  : baselineSlice.reduce((a, b) => a + b) / baselineSlice.length;

              return _SubjectTrend(
                subjectName: entry.key,
                attemptCount: attempts.length,
                averageScore: average,
                trendDelta: recent - baseline,
              );
            })
            .toList()
          ..sort((a, b) => b.averageScore.compareTo(a.averageScore));

        return ListView(
          padding: const EdgeInsets.all(IDPSpacing.md),
          children: [
            const IDPSectionHeader(title: 'Chapter Leaderboard'),
            const SizedBox(height: IDPSpacing.sm),
            ...chapterLeaders.take(10).toList().asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: IDPSpacing.xs),
                child: IDPCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: IDPColors.primaryContainer,
                      foregroundColor: IDPColors.onPrimaryContainer,
                      child: Text('$rank', style: IDPTypography.titleSmall),
                    ),
                    title: Text(row.chapterTitle, style: IDPTypography.titleSmall),
                    subtitle: Text(
                      'Avg ${row.averageScore.toStringAsFixed(1)}% • Best ${row.bestScore}% • ${row.attemptCount} attempts',
                      style: IDPTypography.bodySmall,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: IDPSpacing.lg),
            const IDPSectionHeader(title: 'Subject Progress Trends'),
            const SizedBox(height: IDPSpacing.sm),
            ...subjectTrends.map((trend) {
              final improving = trend.trendDelta >= 0;
              final trendColor = improving ? IDPColors.success : IDPColors.error;
              return Padding(
                padding: const EdgeInsets.only(bottom: IDPSpacing.xs),
                child: IDPCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(trend.subjectName, style: IDPTypography.titleSmall),
                          ),
                          Row(
                            children: [
                              Icon(
                                improving
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color: trendColor,
                                size: 18,
                              ),
                              const SizedBox(width: IDPSpacing.xs / 2),
                              Text(
                                '${trend.trendDelta >= 0 ? '+' : ''}${trend.trendDelta.toStringAsFixed(1)}%',
                                style: IDPTypography.labelMedium.copyWith(color: trendColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: IDPSpacing.xs),
                      Text(
                        'Average ${trend.averageScore.toStringAsFixed(1)}% across ${trend.attemptCount} attempts',
                        style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                      ),
                      const SizedBox(height: IDPSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(IDPRadius.sm),
                        child: LinearProgressIndicator(
                          value: (trend.averageScore / 100).clamp(0, 1),
                          minHeight: 8,
                          backgroundColor: IDPColors.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            trend.averageScore >= 80
                                ? IDPColors.success
                                : trend.averageScore >= 60
                                    ? IDPColors.warning
                                    : IDPColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

}

class _ChapterLeader {
  const _ChapterLeader({
    required this.chapterId,
    required this.chapterTitle,
    required this.attemptCount,
    required this.averageScore,
    required this.bestScore,
  });

  final String chapterId;
  final String chapterTitle;
  final int attemptCount;
  final double averageScore;
  final int bestScore;
}

class _SubjectTrend {
  const _SubjectTrend({
    required this.subjectName,
    required this.attemptCount,
    required this.averageScore,
    required this.trendDelta,
  });

  final String subjectName;
  final int attemptCount;
  final double averageScore;
  final double trendDelta;
}
