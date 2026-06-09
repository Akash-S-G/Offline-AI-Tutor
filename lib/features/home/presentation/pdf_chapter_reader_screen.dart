import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/idp_colors.dart';
import '../../course/domain/curriculum_models.dart';
import '../../course/data/local/pdf_chapter_locator.dart';
import '../../course/data/local/textbook_repository.dart';
import '../../course/domain/textbook_models.dart';
import '../../course/domain/course_tree.dart';
import '../../chat/presentation/chapter_chat_screen.dart';
import 'chapter_summary_screen.dart';
import 'quiz_player_screen.dart';

class PdfChapterReaderScreen extends StatefulWidget {
  final CurriculumChapter chapter;

  const PdfChapterReaderScreen({
    Key? key,
    required this.chapter,
  }) : super(key: key);

  @override
  State<PdfChapterReaderScreen> createState() => _PdfChapterReaderScreenState();
}

class _PdfChapterReaderScreenState extends State<PdfChapterReaderScreen> {
  final Completer<PDFViewController> _pdfViewController = Completer<PDFViewController>();
  final PdfChapterLocator _locator = PdfChapterLocator();
  
  ChapterPdfReference? _pdfRef;
  bool _isLoading = true;
  String? _errorMessage;
  
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    try {
      final ref = await _locator.locateChapterPdf(widget.chapter);
      if (ref == null) {
        setState(() {
          _errorMessage = "PDF not found for this chapter.";
          _isLoading = false;
        });
        return;
      }

      // Check saved progress
      final prefs = await SharedPreferences.getInstance();
      final savedPage = prefs.getInt('reader_progress_${widget.chapter.packId}');
      
      setState(() {
        _pdfRef = ref;
        _currentPage = savedPage ?? ref.startPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load PDF: $e";
        _isLoading = false;
      });
    }
  }

  void _saveProgress(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_progress_${widget.chapter.packId}', page);
  }

  void _onPageChanged(int? page, int? total) {
    if (page == null || total == null) return;
    
    setState(() {
      _currentPage = page;
      _totalPages = total;
    });
    
    _saveProgress(page);

    // Bounds checking (soft restriction)
    if (_pdfRef != null) {
      if (page < _pdfRef!.startPage) {
        _showOutOfBoundsWarning(true);
      } else if (_pdfRef!.endPage != null && page > _pdfRef!.endPage!) {
        _showOutOfBoundsWarning(false);
      }
    }
  }

  void _showOutOfBoundsWarning(bool isBeforeStart) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBeforeStart ? "You've scrolled before the chapter starts." : "You have reached the end of the chapter."),
        action: SnackBarAction(
          label: "Return",
          onPressed: () async {
            final controller = await _pdfViewController.future;
            final targetPage = isBeforeStart ? _pdfRef!.startPage : _pdfRef!.endPage!;
            await controller.setPage(targetPage);
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openTutor() {
    // Map to legacy models to pass to ChapterChatScreen
    final legacyCourse = Course(
      id: 'grade_${widget.chapter.grade}',
      name: 'Grade ${widget.chapter.grade}',
    );
    final legacySubject = Subject(
      id: 'sub_${widget.chapter.subject.toLowerCase()}',
      courseId: legacyCourse.id,
      name: widget.chapter.subject,
    );
    final legacyChapter = Chapter(
      id: widget.chapter.packId,
      subjectId: legacySubject.id,
      title: widget.chapter.title,
      summary: widget.chapter.summary,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterChatScreen(
          course: legacyCourse,
          subject: legacySubject,
          chapter: legacyChapter,
        ),
      ),
    );
  }

  void _openFlashcards() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterSummaryScreen(chapter: widget.chapter),
      ),
    );
  }

  void _openQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPlayerScreen(chapter: widget.chapter),
      ),
    );
  }

  Future<void> _showSummaryPanel() async {
    // Load summary from TextbookRepository as a fallback since summaries.json isn't directly exposed yet
    final repo = TextbookRepository();
    final chapterData = await repo.loadChapter(widget.chapter.rootPath);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: IDPColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Chapter Summary & Concepts",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: IDPColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        if (chapterData == null)
                          const Text("No summary available for this chapter.", style: TextStyle(color: IDPColors.textSecondary))
                        else ...[
                          Text(
                            widget.chapter.summary.isNotEmpty ? widget.chapter.summary : "No summary provided.",
                            style: const TextStyle(fontSize: 16, color: IDPColors.textPrimary, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          const Text("Sections", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: IDPColors.textPrimary)),
                          const SizedBox(height: 12),
                          ...chapterData.sections.map((sec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text("• ${sec.title}", style: const TextStyle(fontSize: 16, color: IDPColors.textSecondary)),
                          )).toList(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chapter.title, style: const TextStyle(fontSize: 16)),
            if (_totalPages > 0)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: IDPColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () {
              // Add bookmark logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bookmarked page ${_currentPage + 1}')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildToolbar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: IDPColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfRef == null) return const SizedBox.shrink();

    return Stack(
      children: [
        PDFView(
          filePath: _pdfRef!.pdfPath,
          enableSwipe: true,
          swipeHorizontal: false, // Vertical scrolling for textbook reading is often preferred
          autoSpacing: false,
          pageFling: false,
          defaultPage: _currentPage,
          fitPolicy: FitPolicy.BOTH,
          onRender: (_pages) {
            setState(() {
              _totalPages = _pages!;
              _isReady = true;
            });
          },
          onError: (error) {
            setState(() {
              _errorMessage = error.toString();
            });
          },
          onPageError: (page, error) {
            setState(() {
              _errorMessage = '$page: ${error.toString()}';
            });
          },
          onViewCreated: (PDFViewController pdfViewController) {
            _pdfViewController.complete(pdfViewController);
          },
          onPageChanged: _onPageChanged,
        ),
        if (!_isReady)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: IDPColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolbarAction(
                icon: Icons.chat_bubble_outline,
                label: "AI Tutor",
                onTap: _openTutor,
                color: IDPColors.primary,
              ),
              _buildToolbarAction(
                icon: Icons.article_outlined,
                label: "Summary",
                onTap: _showSummaryPanel,
                color: Colors.purple,
              ),
              _buildToolbarAction(
                icon: Icons.style_outlined,
                label: "Flashcards",
                onTap: _openFlashcards,
                color: Colors.orange,
              ),
              _buildToolbarAction(
                icon: Icons.quiz_outlined,
                label: "Quiz",
                onTap: _openQuiz,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
