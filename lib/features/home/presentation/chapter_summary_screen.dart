import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../course/domain/curriculum_models.dart';

class ChapterSummaryScreen extends StatefulWidget {
  const ChapterSummaryScreen({
    required this.chapter,
    super.key,
  });

  final CurriculumChapter chapter;

  @override
  State<ChapterSummaryScreen> createState() => _ChapterSummaryScreenState();
}

class _ChapterSummaryScreenState extends State<ChapterSummaryScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  
  List<Map<String, dynamic>> _summaries = [];
  List<Map<String, dynamic>> _flashcards = [];
  
  late TabController _tabController;

  // Flashcards state
  int _cardIndex = 0;
  bool _showBack = false;
  Set<int> _knownCardIndexes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summaryPath = p.join(widget.chapter.rootPath, 'summaries.json');
      final flashcardPath = p.join(widget.chapter.rootPath, 'flashcards.json');

      List<Map<String, dynamic>> parsedSummaries = [];
      List<Map<String, dynamic>> parsedFlashcards = [];

      // Load Summaries
      final sumFile = File(summaryPath);
      if (await sumFile.exists()) {
        final content = await sumFile.readAsString();
        final List<dynamic> decoded = jsonDecode(content);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            parsedSummaries.add(item);
          }
        }
      }

      // Load Flashcards
      final flashFile = File(flashcardPath);
      if (await flashFile.exists()) {
        final content = await flashFile.readAsString();
        final List<dynamic> decoded = jsonDecode(content);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            parsedFlashcards.add(item);
          }
        }
      }

      if (mounted) {
        setState(() {
          _summaries = parsedSummaries;
          _flashcards = parsedFlashcards;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load study notes: $e';
          _loading = false;
        });
      }
    }
  }

  void _flipCard() {
    setState(() {
      _showBack = !_showBack;
    });
  }

  void _markCard(bool known) {
    setState(() {
      if (known) {
        _knownCardIndexes.add(_cardIndex);
      } else {
        _knownCardIndexes.remove(_cardIndex);
      }
      
      // Auto advance to next card if not at end
      if (_cardIndex < _flashcards.length - 1) {
        _cardIndex++;
        _showBack = false;
      } else if (_knownCardIndexes.length == _flashcards.length) {
        // All mastered! Keep index at last or trigger finished
      } else {
        // Loop back to find first unknown
        for (int i = 0; i < _flashcards.length; i++) {
          if (!_knownCardIndexes.contains(i)) {
            _cardIndex = i;
            _showBack = false;
            break;
          }
        }
      }
    });
  }

  void _resetFlashcards() {
    setState(() {
      _cardIndex = 0;
      _showBack = false;
      _knownCardIndexes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.chapter.title),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.description_rounded), text: 'Key Summaries'),
            Tab(icon: Icon(Icons.style_rounded), text: 'Flashcards'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummariesTab(),
                    _buildFlashcardsTab(),
                  ],
                ),
    );
  }

  Widget _buildSummariesTab() {
    if (_summaries.isEmpty) {
      return _buildEmptyState('No summary keypoints available.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _summaries.length,
      itemBuilder: (context, index) {
        final item = _summaries[index];
        final title = item['title'] as String? ?? 'Key Concept';
        final text = item['text'] as String? ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlashcardsTab() {
    if (_flashcards.isEmpty) {
      return _buildEmptyState('No flashcards available.');
    }

    final totalCards = _flashcards.length;
    final masteredCount = _knownCardIndexes.length;
    final allMastered = masteredCount == totalCards;

    if (allMastered) {
      return _buildMasteredView();
    }

    final card = _flashcards[_cardIndex];
    final frontText = card['front'] as String? ?? '';
    final backText = card['back'] as String? ?? '';
    final isKnown = _knownCardIndexes.contains(_cardIndex);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_cardIndex + 1} of $totalCards',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              Text(
                'Mastered: $masteredCount / $totalCards',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: totalCards == 0 ? 0.0 : masteredCount / totalCards,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFFF59E0B),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 32),

          // Card Box (Flip animation via AnimatedSwitcher)
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (widget, animation) {
                  return ScaleTransition(scale: animation, child: widget);
                },
                child: Container(
                  key: ValueKey<bool>(_showBack),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _showBack ? Colors.white : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showBack ? const Color(0xFFE2E8F0) : const Color(0xFFFBBF24),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _showBack ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _showBack ? 'EXPLANATION' : 'TERM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _showBack ? const Color(0xFF475569) : const Color(0xFFB45309),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Text(
                              _showBack ? backText : frontText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _showBack ? 15 : 20,
                                fontWeight: _showBack ? FontWeight.normal : FontWeight.bold,
                                color: const Color(0xFF1E293B),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF94A3B8)),
                          SizedBox(width: 6),
                          Text(
                            'Tap Card to Flip',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Known/Unknown buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _markCard(false),
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  label: const Text('Study Again', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _markCard(true),
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text('Got It!', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasteredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 80,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mastered!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ve successfully reviewed and mastered all the flashcards in this chapter!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _resetFlashcards,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Practice Again'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text(
              'No Study Materials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
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
              'Failed to Load Study Materials',
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
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
