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

  @override
  void initState() {
    super.initState();
    _progressRepository = ProgressRepository();
    _quizRepository = QuizResultRepository();
    _tabController = TabController(length: 2, vsync: this);
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

    for (final course in courses) {
      final subjects = await widget.courseRepository.getSubjects(course.id);
      for (final subject in subjects) {
        final subjectChapters =
            await widget.courseRepository.getChapters(subject.id);
        chapters.addAll(subjectChapters);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChapterProgressTab(),
          _buildQuizHistoryTab(),
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
}
