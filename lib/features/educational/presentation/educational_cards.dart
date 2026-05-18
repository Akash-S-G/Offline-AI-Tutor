import 'package:flutter/material.dart';

/// Educational response card for displaying tutor responses
class EducationalResponseCard extends StatelessWidget {
  final String title;
  final String explanation;
  final List<String> keyPoints;
  final List<String>? examples;
  final String? relatedTopics;
  final int confidence; // 0-100
  final VoidCallback? onContinue;
  final VoidCallback? onRate;

  const EducationalResponseCard({
    Key? key,
    required this.title,
    required this.explanation,
    required this.keyPoints,
    this.examples,
    this.relatedTopics,
    required this.confidence,
    this.onContinue,
    this.onRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with confidence indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Chip(
                    label: Text('$confidence%'),
                    backgroundColor: _getConfidenceColor(confidence),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Main explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  explanation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),

              // Key points
              if (keyPoints.isNotEmpty) ...[
                Text(
                  'Key Points',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...keyPoints.map((point) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(point, style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // Examples
              if (examples != null && examples!.isNotEmpty) ...[
                Text(
                  'Examples',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...examples!.map((example) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          example,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // Related topics
              if (relatedTopics != null && relatedTopics!.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: relatedTopics!.split(',').map((topic) {
                    return Chip(
                      label: Text(topic.trim()),
                      onDeleted: null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onRate != null)
                    TextButton.icon(
                      onPressed: onRate,
                      icon: const Icon(Icons.star_border),
                      label: const Text('Rate'),
                    ),
                  const SizedBox(width: 8),
                  if (onContinue != null)
                    ElevatedButton.icon(
                      onPressed: onContinue,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 75) return Colors.green;
    if (confidence >= 50) return Colors.orange;
    return Colors.red;
  }
}

/// Concept card for displaying educational concept
class ConceptCard extends StatelessWidget {
  final String conceptName;
  final String definition;
  final String? examples;
  final List<String>? relatedConcepts;
  final VoidCallback? onTap;

  const ConceptCard({
    Key? key,
    required this.conceptName,
    required this.definition,
    this.examples,
    this.relatedConcepts,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conceptName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                definition,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (examples != null && examples!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Example: $examples',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiz card for displaying quiz information
class QuizDisplayCard extends StatelessWidget {
  final String quizTitle;
  final int questionCount;
  final int passingScorePercent;
  final int maxAttempts;
  final VoidCallback? onStart;

  const QuizDisplayCard({
    Key? key,
    required this.quizTitle,
    required this.questionCount,
    required this.passingScorePercent,
    required this.maxAttempts,
    this.onStart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quizTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Icon(
                  Icons.quiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                _InfoChip(
                  icon: Icons.question_answer,
                  label: '$questionCount Questions',
                  context: context,
                ),
                _InfoChip(
                  icon: Icons.trending_up,
                  label: '$passingScorePercent% to Pass',
                  context: context,
                ),
                _InfoChip(
                  icon: Icons.repeat,
                  label: '$maxAttempts Attempts',
                  context: context,
                ),
              ],
            ),
            if (onStart != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStart,
                  child: const Text('Start Quiz'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final BuildContext context;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Chapter summary card
class ChapterSummaryCard extends StatelessWidget {
  final String chapterName;
  final String summary;
  final int estimatedMinutes;
  final double progressPercent;
  final VoidCallback? onTap;

  const ChapterSummaryCard({
    Key? key,
    required this.chapterName,
    required this.summary,
    required this.estimatedMinutes,
    required this.progressPercent,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      chapterName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Chip(
                    label: Text('${(progressPercent * 100).toStringAsFixed(0)}%'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$estimatedMinutes min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress overview card
class ProgressOverviewCard extends StatelessWidget {
  final int chaptersCompleted;
  final int totalChapters;
  final int totalMinutesRead;
  final double averageQuizScore;
  final int flashcardsReviewed;

  const ProgressOverviewCard({
    Key? key,
    required this.chaptersCompleted,
    required this.totalChapters,
    required this.totalMinutesRead,
    required this.averageQuizScore,
    required this.flashcardsReviewed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completionPercent = totalChapters == 0 ? 0.0 : chaptersCompleted / totalChapters;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Learning Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.library_books,
                  value: '$chaptersCompleted/$totalChapters',
                  label: 'Chapters',
                  context: context,
                ),
                _StatItem(
                  icon: Icons.timer,
                  value: '$totalMinutesRead',
                  label: 'Minutes',
                  context: context,
                ),
                _StatItem(
                  icon: Icons.school,
                  value: '${averageQuizScore.toStringAsFixed(0)}%',
                  label: 'Avg Score',
                  context: context,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completionPercent,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(completionPercent * 100).toStringAsFixed(0)}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final BuildContext context;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
