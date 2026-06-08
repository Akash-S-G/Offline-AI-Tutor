import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../course/domain/curriculum_models.dart';

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
  List<Map<String, dynamic>> _chunks = [];
  List<String> _sections = [];
  String _currentSection = 'All';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadContent();
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
      final contentPath = p.join(widget.chapter.rootPath, 'content.json');
      final file = File(contentPath);
      if (!await file.exists()) {
        setState(() {
          _error = 'Textbook content file (content.json) not found on disk.';
          _loading = false;
        });
        return;
      }

      final content = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(content);
      
      final List<Map<String, dynamic>> parsedChunks = [];
      final Set<String> uniqueSections = {};

      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          parsedChunks.add(item);
          final metadata = item['metadata'] as Map<String, dynamic>? ?? {};
          final section = metadata['section'] as String? ?? '';
          if (section.trim().isNotEmpty) {
            uniqueSections.add(section.trim());
          }
        }
      }

      if (mounted) {
        setState(() {
          _chunks = parsedChunks;
          _sections = ['All', ...uniqueSections];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to parse textbook content: $e';
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredChunks {
    if (_currentSection == 'All') {
      return _chunks;
    }
    return _chunks.where((chunk) {
      final metadata = chunk['metadata'] as Map<String, dynamic>? ?? {};
      final section = metadata['section'] as String? ?? '';
      return section.trim() == _currentSection;
    }).toList();
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
        title: Text(widget.chapter.title),
        backgroundColor: const Color(0xFF3B82F6),
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _error != null
              ? _buildErrorView()
              : _chunks.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        if (_sections.length > 1) _buildSectionSelectorBar(),
                        Expanded(
                          child: SelectionArea(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              itemCount: _filteredChunks.length,
                              itemBuilder: (context, index) {
                                final chunk = _filteredChunks[index];
                                final text = chunk['text'] as String? ?? '';
                                final metadata = chunk['metadata'] as Map<String, dynamic>? ?? {};
                                return _buildChunkView(text, metadata, index);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildSectionSelectorBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final sec = _sections[index];
          final isSelected = sec == _currentSection;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                sec,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentSection = sec;
                  });
                  _scrollToTop();
                }
              },
              selectedColor: const Color(0xFF3B82F6),
              backgroundColor: const Color(0xFFE2E8F0),
              border: Border.all(color: Colors.transparent),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final sec = _sections[index];
                    final isSelected = sec == _currentSection;
                    return ListTile(
                      title: Text(
                        sec,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      leading: Icon(
                        sec == 'All' ? Icons.library_books_rounded : Icons.label_important_rounded,
                        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_rounded, color: Color(0xFF3B82F6)) : null,
                      onTap: () {
                        setState(() {
                          _currentSection = sec;
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

  Widget _buildChunkView(String text, Map<String, dynamic> metadata, int index) {
    final List<String> lines = text.split('\n');
    final List<Widget> widgets = [];
    
    // Check if the chunk is structured as an example or callout
    final String section = metadata['section'] as String? ?? '';
    final String topic = metadata['topic'] as String? ?? '';
    final String contentType = metadata['contentType'] as String? ?? '';
    
    // Header helper
    if (index == 0 || (metadata['section'] != null && _chunks[index - 1]['metadata']['section'] != metadata['section'])) {
      if (section.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              section.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B82F6),
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      }
    }

    bool inBulletList = false;
    List<String> listItems = [];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        if (inBulletList) {
          widgets.add(_buildBulletList(listItems));
          listItems = [];
          inBulletList = false;
        }
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Check bullet list item
      if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('• ')) {
        inBulletList = true;
        listItems.add(line.substring(2).trim());
        continue;
      }

      if (inBulletList) {
        widgets.add(_buildBulletList(listItems));
        listItems = [];
        inBulletList = false;
      }

      // Render Headings
      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              line.substring(4),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 8),
            child: Text(
              line.substring(3),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 12),
            child: Text(
              line.substring(2),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
        );
      } else if (line.toLowerCase().startsWith('example') || line.toLowerCase().startsWith('activity')) {
        // Styled Example/Activity block
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // Light amber
              borderRadius: BorderRadius.circular(8),
              border: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      line.toLowerCase().startsWith('example') ? Icons.assignment_rounded : Icons.explore_rounded,
                      color: const Color(0xFFB45309),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      line.toLowerCase().startsWith('example') ? 'Example' : 'Activity',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  line.contains(':') ? line.substring(line.indexOf(':') + 1).trim() : line,
                  style: const TextStyle(color: Color(0xFF78350F), height: 1.5, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      } else if (line.toLowerCase().startsWith('note:') || line.toLowerCase().startsWith('important:')) {
        // Styled Callout block
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Light blue
              borderRadius: BorderRadius.circular(8),
              border: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_rounded, color: Color(0xFF1D4ED8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(color: Color(0xFF1E40AF), height: 1.5, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Standard Paragraph
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF334155),
              ),
            ),
          ),
        );
      }
    }

    if (inBulletList) {
      widgets.add(_buildBulletList(listItems));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 6, right: 10),
                child: Icon(Icons.fiber_manual_record, size: 6, color: Color(0xFF64748B)),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
            Icon(Icons.library_books_rounded, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              'No Content Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              'The content file is empty. Check content pack integrity.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
