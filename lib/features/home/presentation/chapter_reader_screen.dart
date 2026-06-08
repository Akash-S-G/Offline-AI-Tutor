import 'package:flutter/material.dart';
import '../../course/domain/curriculum_models.dart';
import '../../course/domain/textbook_models.dart';
import '../../course/data/local/textbook_repository.dart';
import '../../../core/theme/idp_colors.dart';

class ChapterReaderScreen extends StatefulWidget {
  const ChapterReaderScreen({
    required this.chapter,
    super.key,
  });

  final CurriculumChapter chapter;

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  bool _loading = true;
  String? _error;
  TextbookChapter? _textbookChapter;
  List<TextbookSection> _sections = [];
  String _currentSectionId = 'all';
  
  final ScrollController _scrollController = ScrollController();
  int _estimatedTimeMinutes = 0;
  double _scrollProgress = 0.0;
  final TextbookRepository _repository = TextbookRepository();

  @override
  void initState() {
    super.initState();
    _loadContent();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          setState(() {
            _scrollProgress = _scrollController.offset / maxScroll;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final chapter = await _repository.loadChapter(widget.chapter.rootPath);
      if (chapter == null) {
        setState(() {
          _error = 'Textbook structured content not available for this chapter yet. Please update the content pack.';
          _loading = false;
        });
        return;
      }

      int totalWords = 0;
      for (final section in chapter.sections) {
        for (final block in section.blocks) {
          if (block.type == 'paragraph' || block.type == 'example' || block.type == 'definition') {
            totalWords += block.content.split(RegExp(r'\s+')).length;
          }
        }
      }

      final estimatedTime = (totalWords / 200).ceil();

      if (mounted) {
        setState(() {
          _textbookChapter = chapter;
          _sections = chapter.sections;
          _estimatedTimeMinutes = estimatedTime == 0 ? 1 : estimatedTime;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load textbook content: $e';
          _loading = false;
        });
      }
    }
  }

  List<TextbookSection> get _filteredSections {
    if (_textbookChapter == null) return [];
    if (_currentSectionId == 'all') {
      return _sections;
    }
    return _sections.where((sec) => sec.id == _currentSectionId).toList();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chapter.title, style: const TextStyle(fontSize: 18)),
            if (!_loading && _estimatedTimeMinutes > 0)
              Text('$_estimatedTimeMinutes min read', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70)),
          ],
        ),
        backgroundColor: IDPColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_sections.length > 1)
            IconButton(
              icon: const Icon(Icons.toc_rounded),
              tooltip: 'Table of Contents',
              onPressed: _showTOCDrawer,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IDPColors.primary))
          : _error != null
              ? _buildErrorView()
              : _sections.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        if (_sections.length > 1) _buildSectionSelectorBar(),
                        Expanded(
                          child: SelectionArea(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              itemCount: _filteredSections.length,
                              itemBuilder: (context, index) {
                                final section = _filteredSections[index];
                                return _buildSectionView(section);
                              },
                            ),
                          ),
                        ),
                        if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0)
                          LinearProgressIndicator(
                            value: _scrollProgress.clamp(0.0, 1.0),
                            backgroundColor: IDPColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(IDPColors.primary),
                            minHeight: 4,
                          ),
                      ],
                    ),
    );
  }

  Widget _buildSectionSelectorBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: IDPColors.surface,
        border: Border(bottom: BorderSide(color: IDPColors.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _sections.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final secId = isAll ? 'all' : _sections[index - 1].id;
          final secTitle = isAll ? 'All' : _sections[index - 1].title;
          
          final isSelected = secId == _currentSectionId;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                secTitle,
                style: TextStyle(
                  color: isSelected ? Colors.white : IDPColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentSectionId = secId;
                  });
                  _scrollToTop();
                }
              },
              selectedColor: IDPColors.primary,
              backgroundColor: IDPColors.border,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        },
      ),
    );
  }

  void _showTOCDrawer() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Table of Contents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: IDPColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _sections.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final secId = isAll ? 'all' : _sections[index - 1].id;
                    final secTitle = isAll ? 'All' : _sections[index - 1].title;
                    
                    final isSelected = secId == _currentSectionId;
                    return ListTile(
                      title: Text(
                        secTitle,
                        style: TextStyle(
                          color: isSelected ? IDPColors.primary : IDPColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      leading: Icon(
                        isAll ? Icons.library_books_rounded : Icons.label_important_rounded,
                        color: isSelected ? IDPColors.primary : IDPColors.textSecondary,
                      ),
                      trailing: isSelected ? const Icon(Icons.check_rounded, color: IDPColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _currentSectionId = secId;
                        });
                        Navigator.of(context).pop();
                        _scrollToTop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionView(TextbookSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Text(
              section.title.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: IDPColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ...section.blocks.map((block) => _buildBlockView(block)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBlockView(TextbookBlock block) {
    switch (block.type) {
      case 'heading':
        return Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 12),
          child: Text(
            block.content,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: IDPColors.textPrimary),
          ),
        );
      case 'subheading':
        return Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(
            block.content,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: IDPColors.textPrimary),
          ),
        );
      case 'definition':
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: Color(0xFF7E22CE), size: 20),
                  SizedBox(width: 8),
                  Text('Definition', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7E22CE), fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                block.content,
                style: const TextStyle(color: Color(0xFF581C87), height: 1.5, fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      case 'example':
      case 'worked_example':
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_rounded, color: Color(0xFFB45309), size: 20),
                  SizedBox(width: 8),
                  Text('Example', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                block.content,
                style: const TextStyle(color: Color(0xFF78350F), height: 1.5, fontSize: 14),
              ),
            ],
          ),
        );
      case 'formula':
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFECFCCB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF84CC16), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.functions_rounded, color: Color(0xFF4D7C0F), size: 20),
                  SizedBox(width: 8),
                  Text('Formula', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4D7C0F), fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                block.content,
                style: const TextStyle(color: Color(0xFF365314), height: 1.5, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ],
          ),
        );
      case 'note':
      case 'important':
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_rounded, color: Color(0xFF1D4ED8), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  block.content,
                  style: const TextStyle(color: Color(0xFF1E40AF), height: 1.5, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      case 'activity':
      case 'exercise':
        // Activity/Exercise can be a collapsible or just a styled block
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: IDPColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: block.type == 'activity',
              title: Text(
                block.type == 'activity' ? 'Activity' : 'Exercise',
                style: const TextStyle(fontWeight: FontWeight.bold, color: IDPColors.textPrimary),
              ),
              leading: Icon(
                block.type == 'activity' ? Icons.explore_rounded : Icons.fitness_center_rounded,
                color: IDPColors.primary,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      block.content,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: IDPColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'paragraph':
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            block.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: IDPColors.textPrimary,
            ),
          ),
        );
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: IDPColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: IDPColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_rounded, size: 64, color: IDPColors.textHint),
            SizedBox(height: 16),
            Text(
              'No Content Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: IDPColors.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'This chapter does not contain any structured textbook sections.',
              textAlign: TextAlign.center,
              style: TextStyle(color: IDPColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
