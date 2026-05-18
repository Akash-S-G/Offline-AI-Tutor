import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../application/quiz_flashcard_engine.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';
import 'educational_cards.dart';
import 'topic_screen.dart';

/// Shows all topics/concepts available in a specific chapter
class ChapterScreen extends StatefulWidget {
  final ChapterModel chapter;

  const ChapterScreen({
    Key? key,
    required this.chapter,
  }) : super(key: key);

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  late Future<List<ConceptModel>> _conceptsFuture;
  late Future<List<QuizModel>> _quizzesFuture;
  late Future<List<FlashcardModel>> _flashcardsFuture;
  final ProgressTracker _progressTracker = ProgressTracker();

  @override
  void initState() {
    super.initState();
    _conceptsFuture = EducationalRepository.getConceptsByChapterId(widget.chapter.id!);
    _quizzesFuture = EducationalRepository.getQuizzesByChapterId(widget.chapter.id!);
    _flashcardsFuture = EducationalRepository.getFlashcardsByChapterId(widget.chapter.id!);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.chapter.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Topics', icon: Icon(Icons.topic)),
              Tab(text: 'Quizzes', icon: Icon(Icons.quiz)),
              Tab(text: 'Flashcards', icon: Icon(Icons.style)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Topics tab
            _buildTopicsTab(),
            // Quizzes tab
            _buildQuizzesTab(),
            // Flashcards tab
            _buildFlashcardsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsTab() {
    return FutureBuilder<List<ConceptModel>>(
      future: _conceptsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading topics: ${snapshot.error}'),
          );
        }

        final concepts = snapshot.data ?? [];

        if (concepts.isEmpty) {
          return Center(
            child: Text(
              'No topics available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: concepts.length,
          itemBuilder: (context, index) {
            final concept = concepts[index];
            return _ConceptCard(concept: concept);
          },
        );
      },
    );
  }

  Widget _buildQuizzesTab() {
    return FutureBuilder<List<QuizModel>>(
      future: _quizzesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final quizzes = snapshot.data ?? [];

        if (quizzes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No quizzes available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return QuizDisplayCard(
              quizTitle: quiz.title,
              questionCount: quiz.questions.length,
              passingScorePercent: quiz.passingScorePercent,
              maxAttempts: quiz.maxAttempts,
              onStart: () => _startQuiz(quiz),
            );
          },
        );
      },
    );
  }

  Future<void> _startQuiz(QuizModel quiz) async {
    if (quiz.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz is not available yet.')),
      );
      return;
    }

    final questions = await EducationalRepository.getQuizQuestions(quiz.id!);
    if (!mounted) return;

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions available for this quiz yet.')),
      );
      return;
    }

    final session = await QuizEngine().startQuiz(
      quiz.id.toString(),
      chapterId: widget.chapter.id!,
    );

    if (session == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start quiz.')),
      );
      return;
    }

    await _runQuizDialog(quiz, questions, session.id);
  }

  Future<void> _runQuizDialog(
    QuizModel quiz,
    List<QuizQuestion> questions,
    String sessionId,
  ) async {
    var index = 0;
    var selectedAnswer = '';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final question = questions[index];

            return AlertDialog(
              title: Text('Quiz: ${quiz.title}'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Question ${index + 1}/${questions.length}'),
                    const SizedBox(height: 8),
                    Text(question.question),
                    const SizedBox(height: 12),
                    if (question.options.isNotEmpty)
                      ...question.options.map(
                        (option) => RadioListTile<String>(
                          value: option,
                          groupValue: selectedAnswer,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedAnswer = value ?? '';
                            });
                          },
                          title: Text(option),
                        ),
                      )
                    else
                      TextField(
                        onChanged: (value) {
                          selectedAnswer = value;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Type your answer',
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    QuizEngine().abandonQuiz(sessionId);
                    Navigator.pop(context);
                  },
                  child: const Text('Exit'),
                ),
                ElevatedButton(
                  onPressed: selectedAnswer.trim().isEmpty
                      ? null
                      : () async {
                          await QuizEngine().submitAnswer(
                            sessionId,
                            question.id.toString(),
                            selectedAnswer,
                            const Duration(seconds: 10),
                          );

                          if (index < questions.length - 1) {
                            setDialogState(() {
                              index++;
                              selectedAnswer = '';
                            });
                            return;
                          }

                          final completed = await QuizEngine().completeQuiz(sessionId);
                          if (!context.mounted) return;
                          Navigator.pop(context);

                          if (completed != null) {
                            await _updateProgressAfterQuiz(completed);
                            if (!mounted) return;
                            final passed = QuizEngine().checkPassed(
                              completed,
                              quiz.passingScorePercent,
                            );
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${passed ? 'Passed' : 'Completed'} quiz with ${completed.scorePercentage.toStringAsFixed(1)}%',
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(index == questions.length - 1 ? 'Finish' : 'Next'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateProgressAfterQuiz(QuizSession session) async {
    final existing =
        await EducationalRepository.getProgressByChapterId(widget.chapter.id!);
    final nextAttempts = (existing?.quizAttempts ?? 0) + 1;
    final nextBestScore =
        math.max(existing?.quizBestScore ?? 0, session.scorePercentage.round());

    await _progressTracker.updateChapterProgress(
      widget.chapter.id!,
      completionState: existing?.completionState ?? 'in-progress',
      readingProgressPercent: existing?.readingProgressPercent ?? 0,
      quizAttempts: nextAttempts,
      quizBestScore: nextBestScore,
      flashcardsReviewed: existing?.flashcardsReviewed ?? 0,
    );
  }

  Widget _buildFlashcardsTab() {
    return FutureBuilder<List<FlashcardModel>>(
      future: _flashcardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final flashcards = snapshot.data ?? [];

        if (flashcards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.style,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No flashcards available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: flashcards.length,
          itemBuilder: (context, index) {
            final flashcard = flashcards[index];
            return _FlashcardCard(flashcard: flashcard);
          },
        );
      },
    );
  }
}

/// Card for displaying a concept/topic
class _ConceptCard extends StatelessWidget {
  final ConceptModel concept;

  const _ConceptCard({required this.concept});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${concept.sequenceNumber}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(concept.name),
        subtitle: concept.definition != null
            ? Text(
                concept.definition!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicScreen(concept: concept),
            ),
          );
        },
      ),
    );
  }
}

/// Card for displaying a quiz
/// Card for displaying a flashcard
class _FlashcardCard extends StatefulWidget {
  final FlashcardModel flashcard;

  const _FlashcardCard({required this.flashcard});

  @override
  State<_FlashcardCard> createState() => _FlashcardCardState();
}

class _FlashcardCardState extends State<_FlashcardCard> {
  bool _showDefinition = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDefinition = !_showDefinition;
        });
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _showDefinition
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.secondaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showDefinition ? 'Definition' : 'Term',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Icon(
                    _showDefinition ? Icons.flip : Icons.rotate_left,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _showDefinition ? widget.flashcard.definition : widget.flashcard.term,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (widget.flashcard.example != null && _showDefinition) ...[
                const SizedBox(height: 12),
                Text(
                  'Example:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.flashcard.example!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to flip',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
