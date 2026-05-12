import 'package:flutter/material.dart';

import '../../course/data/local/course_repository.dart';
import '../../course/domain/course_tree.dart';
import '../data/local/progress_repository.dart';
import '../../assessment/data/local/quiz_result_repository.dart';
import '../../assessment/domain/quiz_result.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({
    required this.courseRepository,
    super.key,
  });

  final CourseRepository courseRepository;

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
    final courses = await widget.courseRepository.getCourses();
    final chapters = <Chapter>[];
    final chapterTitleById = <String, String>{};
    final chapterSubjectById = <String, String>{};

    for (final course in courses) {
      final subjects = await widget.courseRepository.getSubjects(course.id);
      for (final subject in subjects) {
        final subjectChapters =
            await widget.courseRepository.getChapters(subject.id);
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
      appBar: AppBar(
        title: const Text('Learning Progress'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chapter Progress'),
            Tab(text: 'Quiz History'),
            Tab(text: 'Leaderboard & Trends'),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (_chaptersWithProgress.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No progress yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start tutoring to see your progress',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
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
          padding: const EdgeInsets.all(16),
          children: [
            // Overall summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Mastery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${averageMastery.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_chaptersWithProgress.length} chapters',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: averageMastery / 100,
                              minHeight: 12,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                averageMastery >= 80
                                    ? Colors.green
                                    : averageMastery >= 50
                                        ? Colors.orange
                                        : Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chapter Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // Per-chapter cards
            ...List.generate(
              _chaptersWithProgress.length,
              (index) {
                final cwp = _chaptersWithProgress[index];
                final color = _masteryLevelColor(cwp.progress.masteryLevel);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cwp.chapter.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Active ${_formatLastActivity(cwp.progress.lastActivityAt)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  cwp.progress.masteryLevel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: cwp.progress.masteryScore / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${cwp.progress.masteryScore.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.question_answer_rounded,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cwp.progress.questionsAsked} Q',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.chat_rounded,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cwp.progress.totalMessages} msgs',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cwp.progress.sessionsEngaged} sess',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (_allQuizResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.quiz_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No quizzes attempted yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take quizzes from the Learning Materials',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Recent Quiz Attempts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._allQuizResults.take(20).map((result) {
              final performanceColor = result.percentage >= 80
                  ? Colors.green
                  : result.percentage >= 60
                      ? Colors.orange
                      : Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatQuizDate(result.attemptedAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: performanceColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${result.percentage}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: performanceColor,
                                  ),
                                ),
                                Text(
                                  result.performanceLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: performanceColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${result.score}/${result.totalQuestions} correct',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            result.passed
                                ? Icons.thumb_up_rounded
                                : Icons.info_rounded,
                            size: 14,
                            color: performanceColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.passed ? 'Passed' : 'Needs Work',
                            style: TextStyle(
                              fontSize: 12,
                              color: performanceColor,
                              fontWeight: FontWeight.w500,
                            ),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (_allQuizResults.isEmpty) {
          return const Center(
            child: Text('Take quizzes to unlock leaderboard and trend analytics.'),
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
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Chapter Leaderboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ...chapterLeaders.take(10).toList().asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final row = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('$rank'),
                  ),
                  title: Text(row.chapterTitle),
                  subtitle: Text(
                    'Avg ${row.averageScore.toStringAsFixed(1)}% • Best ${row.bestScore}% • ${row.attemptCount} attempts',
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Subject Progress Trends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ...subjectTrends.map((trend) {
              final improving = trend.trendDelta >= 0;
              final trendColor = improving ? Colors.green : Colors.red;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              trend.subjectName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
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
                              const SizedBox(width: 4),
                              Text(
                                '${trend.trendDelta >= 0 ? '+' : ''}${trend.trendDelta.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: trendColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Average ${trend.averageScore.toStringAsFixed(1)}% across ${trend.attemptCount} attempts',
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (trend.averageScore / 100).clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          trend.averageScore >= 80
                              ? Colors.green
                              : trend.averageScore >= 60
                                  ? Colors.orange
                                  : Colors.red,
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
