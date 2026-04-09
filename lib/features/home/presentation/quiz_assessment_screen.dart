import 'dart:math';

import 'package:flutter/material.dart';

import '../../course/domain/course_tree.dart';
import '../../assessment/domain/quiz_result.dart';
import '../../assessment/data/local/quiz_result_repository.dart';

class QuizAssessmentScreen extends StatefulWidget {
  const QuizAssessmentScreen({
    required this.course,
    required this.subject,
    required this.chapter,
    super.key,
  });

  final Course course;
  final Subject subject;
  final Chapter chapter;

  @override
  State<QuizAssessmentScreen> createState() => _QuizAssessmentScreenState();
}

class _QuizAssessmentScreenState extends State<QuizAssessmentScreen> {
  late final List<_QuizQuestion> _questions;
  late final QuizResultRepository _resultRepository;
  final Map<int, int> _answers = <int, int>{};
  bool _submitted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _resultRepository = QuizResultRepository();
    _questions = _buildQuestions(widget.course, widget.subject, widget.chapter);
  }

  int get _score {
    var score = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].correctIndex) {
        score++;
      }
    }
    return score;
  }

  Future<void> _submitQuiz() async {
    if (_answers.length != _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer all questions before submitting.')),
      );
      return;
    }

    setState(() {
      _submitted = true;
      _saving = true;
    });

    try {
      final result = QuizResult(
        chapterId: widget.chapter.id,
        score: _score,
        totalQuestions: _questions.length,
        answers: Map<int, int>.from(_answers),
        attemptedAt: DateTime.now(),
      );

      await _resultRepository.saveResult(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quiz saved! Score: ${result.percentage}% (${result.performanceLabel})',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save quiz result: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _resetQuiz() {
    setState(() {
      _answers.clear();
      _submitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final pct = _questions.isEmpty ? 0 : ((score * 100) / _questions.length).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz & Assessment'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chapter.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.course.name} • ${widget.subject.name}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  if (_submitted) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Score: $score/${_questions.length} ($pct%)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final selected = _answers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}. ${question.prompt}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    ...question.options.asMap().entries.map((opt) {
                      final optionIndex = opt.key;
                      final isCorrect = optionIndex == question.correctIndex;
                      final isSelected = selected == optionIndex;
                      Color? tileColor;
                      if (_submitted && isCorrect) {
                        tileColor = Colors.green.withValues(alpha: 0.12);
                      } else if (_submitted && isSelected && !isCorrect) {
                        tileColor = Colors.red.withValues(alpha: 0.12);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RadioListTile<int>(
                          value: optionIndex,
                          groupValue: selected,
                          onChanged: _submitted
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _answers[index] = value;
                                  });
                                },
                          title: Text(opt.value),
                          dense: true,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          if (!_submitted)
            FilledButton.icon(
              onPressed: _saving ? null : _submitQuiz,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(_saving ? 'Saving...' : 'Submit Quiz'),
            )
          else
            OutlinedButton.icon(
              onPressed: _resetQuiz,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Retake Quiz'),
            ),
        ],
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
}

List<_QuizQuestion> _buildQuestions(Course course, Subject subject, Chapter chapter) {
  final keywordPool = _extractKeywords(chapter.summary);
  final mainKeyword = keywordPool.isNotEmpty ? keywordPool.first : chapter.title;
  final secondKeyword = keywordPool.length > 1 ? keywordPool[1] : subject.name;

  final distractors = <String>[
    'Photosynthesis',
    'Trigonometry',
    'Atomic Structure',
    'World History',
    'Data Types',
    'Ecosystem',
  ];

  final random = Random(chapter.id.hashCode);
  distractors.shuffle(random);

  return <_QuizQuestion>[
    _quizWithShuffledAnswer(
      prompt: 'Which chapter is this quiz based on?',
      correct: chapter.title,
      wrong: <String>[subject.name, course.name, distractors[0]],
      random: random,
    ),
    _quizWithShuffledAnswer(
      prompt: 'This chapter mainly belongs to which subject?',
      correct: subject.name,
      wrong: <String>[course.name, distractors[1], distractors[2]],
      random: random,
    ),
    _quizWithShuffledAnswer(
      prompt: 'Which term is most likely central to this chapter summary?',
      correct: mainKeyword,
      wrong: <String>[distractors[3], distractors[4], distractors[5]],
      random: random,
    ),
    _quizWithShuffledAnswer(
      prompt: 'Choose the likely secondary concept discussed in this chapter.',
      correct: secondKeyword,
      wrong: <String>[distractors[0], distractors[2], distractors[4]],
      random: random,
    ),
    _quizWithShuffledAnswer(
      prompt: 'Best next step after this quiz?',
      correct: 'Review mistakes and ask AI Tutor targeted doubts',
      wrong: <String>[
        'Skip revision entirely',
        'Memorize answers without understanding',
        'Ignore chapter summary',
      ],
      random: random,
    ),
  ];
}

_QuizQuestion _quizWithShuffledAnswer({
  required String prompt,
  required String correct,
  required List<String> wrong,
  required Random random,
}) {
  final options = <String>[correct, ...wrong]..shuffle(random);
  return _QuizQuestion(
    prompt: prompt,
    options: options,
    correctIndex: options.indexOf(correct),
  );
}

List<String> _extractKeywords(String text) {
  final cleaned = text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length >= 5)
      .where(
        (w) =>
            !const <String>{
              'about',
              'these',
              'their',
              'there',
              'which',
              'chapter',
              'learn',
              'understand',
              'topic',
              'topics',
            }.contains(w),
      )
      .toList();

  final unique = <String>[];
  for (final word in cleaned) {
    if (!unique.contains(word)) {
      unique.add(word);
    }
    if (unique.length == 6) {
      break;
    }
  }
  return unique;
}
