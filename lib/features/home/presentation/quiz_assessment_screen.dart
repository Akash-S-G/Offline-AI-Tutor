import 'dart:math';

import 'package:flutter/material.dart';

import '../../course/domain/course_tree.dart';
import '../../assessment/domain/quiz_result.dart';
import '../../assessment/data/local/quiz_result_repository.dart';
import '../../rag/data/local/rag_repository.dart';
import '../../rag/domain/rag_chunk.dart';

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
  List<_QuizQuestion> _questions = const [];
  late final QuizResultRepository _resultRepository;
  late final RagRepository _ragRepository;
  final Map<int, int> _answers = <int, int>{};
  _QuizMode _quizMode = _QuizMode.quick;
  bool _submitted = false;
  bool _saving = false;
  bool _generatingQuestions = false;
  int _quizGenerationNonce = 0;

  @override
  void initState() {
    super.initState();
    _resultRepository = QuizResultRepository();
    _ragRepository = RagRepository();
    _regenerateQuiz();
  }

  Future<void> _regenerateQuiz() async {
    setState(() {
      _generatingQuestions = true;
      _answers.clear();
      _submitted = false;
      _questions = const [];
    });

    final random = Random(
      widget.chapter.id.hashCode ^
          DateTime.now().microsecondsSinceEpoch ^
          _quizGenerationNonce,
    );
    _quizGenerationNonce += 1;

    List<_QuizQuestion> questions;
    try {
      final chunks = await _ragRepository.getChunksForChapter(widget.chapter.id);
      final ragQuestions = _buildRagBackedQuestions(
        chunks: chunks,
        chapter: widget.chapter,
        subject: widget.subject,
        course: widget.course,
        count: _quizMode.questionCount,
        random: random,
      );

      if (ragQuestions.length >= _quizMode.questionCount) {
        questions = ragQuestions.take(_quizMode.questionCount).toList();
      } else {
        final fallback = _buildTemplateQuestions(
          widget.course,
          widget.subject,
          widget.chapter,
          count: _quizMode.questionCount,
          random: random,
        );
        questions = <_QuizQuestion>[...ragQuestions, ...fallback]
            .take(_quizMode.questionCount)
            .toList();
      }
    } catch (_) {
      questions = _buildTemplateQuestions(
        widget.course,
        widget.subject,
        widget.chapter,
        count: _quizMode.questionCount,
        random: random,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _questions = questions;
      _generatingQuestions = false;
    });
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
    final answeredCount = _answers.length;

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
                  const SizedBox(height: 10),
                  SegmentedButton<_QuizMode>(
                    segments: const [
                      ButtonSegment(
                        value: _QuizMode.quick,
                        label: Text('Quick'),
                        icon: Icon(Icons.flash_on_rounded),
                      ),
                      ButtonSegment(
                        value: _QuizMode.standard,
                        label: Text('Standard'),
                        icon: Icon(Icons.menu_book_rounded),
                      ),
                      ButtonSegment(
                        value: _QuizMode.challenge,
                        label: Text('Challenge'),
                        icon: Icon(Icons.emoji_events_rounded),
                      ),
                    ],
                    selected: {_quizMode},
                    onSelectionChanged: _saving
                        ? null
                        : (selection) {
                            setState(() {
                              _quizMode = selection.first;
                            });
                            _regenerateQuiz();
                          },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generatingQuestions
                        ? 'Generating questions from chapter chunks...'
                        : 'Questions source: Chapter RAG chunks (fallbacks only if needed)',
                    style: TextStyle(
                      fontSize: 12,
                      color: _generatingQuestions
                          ? const Color(0xFF1D4ED8)
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Progress: $answeredCount/${_questions.length} answered'),
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
          if (_generatingQuestions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
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
                    if (_submitted) ...[
                      const SizedBox(height: 8),
                      Text(
                        selected == question.correctIndex
                            ? 'Correct'
                            : 'Incorrect',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected == question.correctIndex
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Why: ${question.explanation}'),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          if (!_submitted)
            FilledButton.icon(
              onPressed: (_saving || _generatingQuestions || _questions.isEmpty)
                  ? null
                  : _submitQuiz,
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
          else ...[
            OutlinedButton.icon(
              onPressed: _resetQuiz,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Retake Same Quiz'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _regenerateQuiz,
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Generate New Quiz Set'),
            ),
          ],
        ],
      ),
    );
  }
}

enum _QuizMode {
  quick,
  standard,
  challenge,
}

extension on _QuizMode {
  int get questionCount {
    switch (this) {
      case _QuizMode.quick:
        return 5;
      case _QuizMode.standard:
        return 10;
      case _QuizMode.challenge:
        return 15;
    }
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

List<_QuizQuestion> _buildTemplateQuestions(
  Course course,
  Subject subject,
  Chapter chapter, {
  required int count,
  required Random random,
}) {
  final keywordPool = _extractKeywords(chapter.summary);
  final mainKeyword = keywordPool.isNotEmpty ? keywordPool.first : chapter.title;
  final secondKeyword = keywordPool.length > 1 ? keywordPool[1] : subject.name;
  final thirdKeyword = keywordPool.length > 2 ? keywordPool[2] : course.name;

  final distractors = <String>[
    'Photosynthesis',
    'Trigonometry',
    'Atomic Structure',
    'World History',
    'Data Types',
    'Ecosystem',
  ];

  distractors.shuffle(random);

  final base = <_QuizQuestion>[
    _quizWithShuffledAnswer(
      prompt: 'Which chapter is this quiz based on?',
      correct: chapter.title,
      wrong: <String>[subject.name, course.name, distractors[0]],
      explanation:
          'The quiz context is tied to the selected chapter: ${chapter.title}.',
      random: random,
    ),
    _quizWithShuffledAnswer(
      prompt: 'This chapter mainly belongs to which subject?',
      correct: subject.name,
      wrong: <String>[course.name, distractors[1], distractors[2]],
      explanation:
          'The chapter is loaded under ${subject.name}, so that is the correct subject mapping.',
      random: random,
    ),
    _quizWithShuffledAnswer(
      prompt: 'Which term is most likely central to this chapter summary?',
      correct: mainKeyword,
      wrong: <String>[distractors[3], distractors[4], distractors[5]],
      explanation:
          'This keyword appears as a high-signal concept in the chapter summary text.',
      random: random,
    ),
    _quizWithShuffledAnswer(
      prompt: 'Choose the likely secondary concept discussed in this chapter.',
      correct: secondKeyword,
      wrong: <String>[distractors[0], distractors[2], distractors[4]],
      explanation:
          'The secondary concept is derived from summary keywords and chapter context.',
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
      explanation:
          'Best learning practice is review + targeted doubt-solving, not rote memorization.',
      random: random,
    ),
    _quizWithShuffledAnswer(
      prompt: 'Which concept is most directly tied to this chapter context?',
      correct: thirdKeyword,
      wrong: <String>[distractors[0], distractors[1], distractors[2]],
      explanation:
          'This concept is selected from chapter-linked keywords and is more relevant than generic distractors.',
      random: random,
    ),
    _quizWithShuffledAnswer(
      prompt: 'Which option is the least relevant to the selected chapter?',
      correct: distractors[1],
      wrong: <String>[mainKeyword, secondKeyword, thirdKeyword],
      explanation:
          'This distractor is intentionally outside the chapter context while the others are extracted from chapter metadata.',
      random: random,
    ),
    _quizWithShuffledAnswer(
      prompt: 'This chapter appears under which course?',
      correct: course.name,
      wrong: <String>[subject.name, distractors[3], distractors[4]],
      explanation:
          'The selected chapter is loaded from the currently selected course in dashboard context.',
      random: random,
    ),
  ];

  if (count <= base.length) {
    return base.take(count).toList();
  }

  final expanded = <_QuizQuestion>[...base];
  while (expanded.length < count) {
    final keyword = keywordPool.isEmpty
        ? chapter.title
        : keywordPool[expanded.length % keywordPool.length];
    final d1 = distractors[(expanded.length + 1) % distractors.length];
    final d2 = distractors[(expanded.length + 3) % distractors.length];
    final d3 = distractors[(expanded.length + 5) % distractors.length];
    expanded.add(
      _quizWithShuffledAnswer(
        prompt: 'Pick the chapter-aligned term from this set.',
        correct: keyword,
        wrong: <String>[d1, d2, d3],
        explanation:
            'The correct option is selected from chapter-derived keywords while other options are generic distractors.',
        random: random,
      ),
    );
  }

  return expanded;
}

List<_QuizQuestion> _buildRagBackedQuestions({
  required List<RagChunk> chunks,
  required Course course,
  required Subject subject,
  required Chapter chapter,
  required int count,
  required Random random,
}) {
  if (chunks.isEmpty) {
    return const [];
  }

  final stopWords = <String>{
    'the',
    'and',
    'that',
    'with',
    'from',
    'have',
    'this',
    'into',
    'where',
    'using',
    'both',
    'sides',
    'chapter',
    'notes',
    'their',
    'there',
    'which',
  };

  final allSentences = <String>[];
  final vocabulary = <String>{};
  for (final chunk in chunks) {
    final sentences = chunk.content
        .replaceAll('\n', ' ')
        .split(RegExp(r'[.!?]'))
        .map((s) => s.trim())
        .where((s) => s.length >= 30)
        .toList();
    allSentences.addAll(sentences);

    final words = chunk.content
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length >= 5)
        .where((w) => !stopWords.contains(w));
    vocabulary.addAll(words);
  }

  if (allSentences.isEmpty || vocabulary.length < 4) {
    return const [];
  }

  allSentences.shuffle(random);
  final vocabList = vocabulary.toList()..shuffle(random);

  final questions = <_QuizQuestion>[];
  for (final sentence in allSentences) {
    if (questions.length >= count) {
      break;
    }

    final answer = _pickAnswerToken(sentence, stopWords, random);
    if (answer == null || answer.length < 4) {
      continue;
    }

    final masked = _maskFirstToken(sentence, answer);
    if (masked == sentence) {
      continue;
    }

    final distractors = <String>[];
    for (final token in vocabList) {
      if (token == answer) {
        continue;
      }
      if (distractors.contains(token)) {
        continue;
      }
      distractors.add(token);
      if (distractors.length == 3) {
        break;
      }
    }
    if (distractors.length < 3) {
      continue;
    }

    final normalizedAnswer = _titleCase(answer);
    final normalizedDistractors = distractors.map(_titleCase).toList();

    questions.add(
      _quizWithShuffledAnswer(
        prompt:
            'Complete from chapter notes: "$masked"',
        correct: normalizedAnswer,
        wrong: normalizedDistractors,
        explanation:
            'This is taken directly from chapter content: "$sentence"',
        random: random,
      ),
    );
  }

  if (questions.length < count) {
    final chunkCountQuestion = _quizWithShuffledAnswer(
      prompt: 'How many note chunks are currently indexed for this chapter?',
      correct: chunks.length.toString(),
      wrong: <String>[
        max(1, chunks.length - 1).toString(),
        (chunks.length + 1).toString(),
        (chunks.length + 3).toString(),
      ],
      explanation:
          'Quiz generation reads the indexed chapter chunks from local RAG storage.',
      random: random,
    );
    questions.add(chunkCountQuestion);
  }

  if (questions.length < count) {
    questions.add(
      _quizWithShuffledAnswer(
        prompt: 'These RAG-backed questions belong to which chapter?',
        correct: chapter.title,
        wrong: <String>[subject.name, course.name, 'General Practice'],
        explanation:
            'Question generation is scoped by selected chapter id and not global content.',
        random: random,
      ),
    );
  }

  return questions;
}

String? _pickAnswerToken(String sentence, Set<String> stopWords, Random random) {
  final candidates = sentence
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length >= 5)
      .where((w) => !stopWords.contains(w))
      .toSet()
      .toList();
  if (candidates.isEmpty) {
    return null;
  }
  candidates.shuffle(random);
  return candidates.first;
}

String _maskFirstToken(String sentence, String token) {
  final regExp = RegExp('\\b${RegExp.escape(token)}\\b', caseSensitive: false);
  return sentence.replaceFirst(regExp, '_____');
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

_QuizQuestion _quizWithShuffledAnswer({
  required String prompt,
  required String correct,
  required List<String> wrong,
  required String explanation,
  required Random random,
}) {
  final options = <String>[correct, ...wrong]..shuffle(random);
  return _QuizQuestion(
    prompt: prompt,
    options: options,
    correctIndex: options.indexOf(correct),
    explanation: explanation,
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
