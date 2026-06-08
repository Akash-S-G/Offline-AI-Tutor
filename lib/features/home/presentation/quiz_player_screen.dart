import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../course/domain/curriculum_models.dart';
import '../../assessment/data/local/quiz_result_repository.dart';
import '../../assessment/domain/quiz_result.dart';

class QuizQuestion {
  QuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
    required this.correctIndex,
  });

  final String question;
  final String correctAnswer;
  final List<String> options;
  final int correctIndex;
}

class QuizPlayerScreen extends StatefulWidget {
  const QuizPlayerScreen({
    required this.chapter,
    super.key,
  });

  final CurriculumChapter chapter;

  @override
  State<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends State<QuizPlayerScreen> {
  final QuizResultRepository _quizRepo = QuizResultRepository();
  bool _loading = true;
  String? _error;
  
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _checked = false;
  int _score = 0;
  Map<int, int> _answers = {}; // questionIndex -> selectedIndex
  
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final quizPath = p.join(widget.chapter.rootPath, 'quizzes.json');
      final file = File(quizPath);
      if (!await file.exists()) {
        setState(() {
          _questions = [];
          _loading = false;
        });
        return;
      }

      final content = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(content);
      
      final List<Map<String, dynamic>> rawQuizzes = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          rawQuizzes.add(item);
        }
      }

      final random = Random();
      final List<QuizQuestion> parsedQuestions = [];

      for (var i = 0; i < rawQuizzes.length; i++) {
        final current = rawQuizzes[i];
        final question = current['question'] as String? ?? '';
        final correct = current['correct_answer'] as String? ?? '';

        if (question.isEmpty || correct.isEmpty) {
          continue;
        }

        // Get distractors from other questions
        final otherAnswers = rawQuizzes
            .where((q) => q['correct_answer'] != correct)
            .map((q) => q['correct_answer'] as String? ?? '')
            .where((a) => a.isNotEmpty)
            .toList();

        otherAnswers.shuffle(random);
        
        final List<String> options = [correct];
        options.addAll(otherAnswers.take(2));

        // Add static fallbacks if not enough options
        final fallbacks = [
          "Information not specified in this section.",
          "None of the above statements are correct.",
          "All of the above statements apply here.",
          "Both options A and B are incorrect."
        ];
        fallbacks.shuffle(random);
        
        while (options.length < 4) {
          final f = fallbacks.removeLast();
          if (!options.contains(f)) {
            options.add(f);
          }
        }

        options.shuffle(random);
        final correctIndex = options.indexOf(correct);

        parsedQuestions.add(QuizQuestion(
          question: question,
          correctAnswer: correct,
          options: options,
          correctIndex: correctIndex,
        ));
      }

      if (mounted) {
        setState(() {
          _questions = parsedQuestions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load quizzes: $e';
          _loading = false;
        });
      }
    }
  }

  void _selectOption(int index) {
    if (_checked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == null || _checked) return;

    final q = _questions[_currentIndex];
    final isCorrect = _selectedOptionIndex == q.correctIndex;
    
    setState(() {
      _checked = true;
      _answers[_currentIndex] = _selectedOptionIndex!;
      if (isCorrect) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _checked = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    // Save result to DB
    final result = QuizResult(
      chapterId: widget.chapter.packId,
      score: _score,
      totalQuestions: _questions.length,
      answers: _answers,
      attemptedAt: DateTime.now(),
    );
    await _quizRepo.saveResult(result);

    if (mounted) {
      setState(() {
        _quizFinished = true;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _checked = false;
      _score = 0;
      _answers = {};
      _quizFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.chapter.title} Quiz'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _error != null
              ? _buildErrorView()
              : _questions.isEmpty
                  ? _buildEmptyState()
                  : _quizFinished
                      ? _buildResultsView()
                      : _buildQuizPlayView(),
    );
  }

  Widget _buildQuizPlayView() {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF10B981),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),

          // Question Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              q.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.4),
            ),
          ),
          const SizedBox(height: 20),

          // Options List
          Expanded(
            child: ListView.builder(
              itemCount: q.options.length,
              itemBuilder: (context, index) {
                final optionText = q.options[index];
                final isSelected = _selectedOptionIndex == index;
                
                Color cardColor = Colors.white;
                Color borderColor = const Color(0xFFE2E8F0);
                Color textColor = const Color(0xFF334155);

                if (_checked) {
                  if (index == q.correctIndex) {
                    cardColor = const Color(0xFFECFDF5);
                    borderColor = const Color(0xFF10B981);
                    textColor = const Color(0xFF065F46);
                  } else if (isSelected) {
                    cardColor = const Color(0xFFFEF2F2);
                    borderColor = const Color(0xFFEF4444);
                    textColor = const Color(0xFF991B1B);
                  }
                } else if (isSelected) {
                  cardColor = const Color(0xFFECFDF5);
                  borderColor = const Color(0xFF10B981);
                  textColor = const Color(0xFF047857);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _selectOption(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: isSelected || _checked ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(fontSize: 14, color: textColor, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Action Button
          if (!_checked)
            FilledButton(
              onPressed: _selectedOptionIndex == null ? null : _checkAnswer,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Check Answer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explanation:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.correctAnswer,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _nextQuestion,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1 ? 'Next Question' : 'Finish Quiz',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final pct = (_score * 100 / _questions.length).round();
    final isPass = pct >= 60;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(
            isPass ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
            size: 80,
            color: isPass ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
          ),
          const SizedBox(height: 16),
          Text(
            isPass ? 'Congratulations!' : 'Keep Learning!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            isPass ? 'You did a great job on this chapter quiz.' : 'Try reading the textbook content again and retry.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Score Indicator Circle
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isPass ? const Color(0xFF10B981) : const Color(0xFF94A3B8), width: 6),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_score / ${_questions.length}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pct%',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isPass ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Breakdown section
          const Text(
            'Question Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          ...List.generate(_questions.length, (idx) {
            final q = _questions[idx];
            final userSel = _answers[idx];
            final correct = q.correctIndex;
            final isCorrect = userSel == correct;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${idx + 1}: ${q.question}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your Answer: ${userSel != null ? q.options[userSel] : "None"}',
                          style: TextStyle(fontSize: 12, color: isCorrect ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w500),
                        ),
                        if (!isCorrect)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Correct Answer: ${q.options[correct]}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _restartQuiz,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retry Quiz', style: TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Quiz',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadQuiz,
              child: const Text('Retry'),
            ),
          ],
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
            const Icon(Icons.quiz_outlined, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text(
              'No Practice Quizzes Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no precomputed quiz questions available in this content pack yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Go Back', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
