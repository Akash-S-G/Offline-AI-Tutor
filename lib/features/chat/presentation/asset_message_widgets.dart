import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ASSET TYPE DETECTION
// ─────────────────────────────────────────────────────────────────────────────

/// Identifies the type of structured asset response from text markers.
enum AssetMessageType {
  flashcard,
  quiz,
  glossary,
  summary,
  worksheet,
  plain,
}

AssetMessageType detectAssetType(String text) {
  if (text.startsWith('**📇 Source: Flashcard**')) return AssetMessageType.flashcard;
  if (text.startsWith('**📝 Source: Quiz**')) return AssetMessageType.quiz;
  if (text.startsWith('**📖 Source: Glossary**')) return AssetMessageType.glossary;
  if (text.startsWith('**📋 Source: Chapter Summary**')) return AssetMessageType.summary;
  if (text.startsWith('**📝 Source: Worksheet**')) return AssetMessageType.worksheet;
  return AssetMessageType.plain;
}

// ─────────────────────────────────────────────────────────────────────────────
// FLASHCARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class FlashcardMessageWidget extends StatefulWidget {
  const FlashcardMessageWidget({required this.text, super.key});
  final String text;

  @override
  State<FlashcardMessageWidget> createState() => _FlashcardMessageWidgetState();
}

class _FlashcardMessageWidgetState extends State<FlashcardMessageWidget>
    with SingleTickerProviderStateMixin {
  bool _flipped = false;

  Map<String, String> get _parsed {
    final lines = widget.text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    String term = '', definition = '', example = '';
    for (final line in lines) {
      if (line.startsWith('**Term:**')) term = line.replaceFirst('**Term:**', '').trim();
      if (line.startsWith('**Definition:**')) definition = line.replaceFirst('**Definition:**', '').trim();
      if (line.startsWith('**Example:**')) example = line.replaceFirst('**Example:**', '').trim();
    }
    return {'term': term, 'definition': definition, 'example': example};
  }

  @override
  Widget build(BuildContext context) {
    final data = _parsed;
    return GestureDetector(
      onTap: () => setState(() => _flipped = !_flipped),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _flipped
                ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                : [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.style, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'FLASHCARD',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Icon(
                  _flipped ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white38,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data['term'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_flipped) ...[
              const Divider(color: Colors.white30, height: 24),
              Text(
                data['definition'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
              ),
              if (data['example']?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['example']!,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                'Tap to reveal answer',
                style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUIZ WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class QuizMessageWidget extends StatelessWidget {
  const QuizMessageWidget({required this.text, super.key});
  final String text;

  Map<String, String> get _parsed {
    final lines = widget_text_lines;
    String title = '', description = '', meta = '';
    for (final line in lines) {
      if (line.startsWith('**Quiz:**')) title = line.replaceFirst('**Quiz:**', '').trim();
      if (line.startsWith('**Questions:')) meta = line.replaceAll('**', '').trim();
    }
    // Get description: lines between title and meta
    final titleIdx = lines.indexWhere((l) => l.startsWith('**Quiz:**'));
    final metaIdx = lines.indexWhere((l) => l.startsWith('**Questions:'));
    if (titleIdx >= 0 && metaIdx > titleIdx + 1) {
      description = lines.sublist(titleIdx + 1, metaIdx).join('\n').trim();
    }
    return {'title': title, 'description': description, 'meta': meta};
  }

  List<String> get widget_text_lines =>
      text.split('\n').where((l) => l.trim().isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final data = _parsed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'QUIZ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data['title'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (data['description']?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              data['description']!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          if (data['meta']?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data['meta']!,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Navigate-to-quiz hint
          Row(
            children: [
              const Icon(Icons.arrow_forward, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Navigate to Quizzes tab to start interactively',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOSSARY WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class GlossaryMessageWidget extends StatelessWidget {
  const GlossaryMessageWidget({required this.text, super.key});
  final String text;

  List<Map<String, String>> get _entries {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final entries = <Map<String, String>>[];

    // Single concept format
    String? currentTerm, currentDef, currentEx;
    for (final line in lines) {
      if (line.startsWith('**Concept:**') || line.startsWith('**Term:**')) {
        currentTerm = line.replaceFirst(RegExp(r'\*\*(Concept|Term):\*\*'), '').trim();
      } else if (line.startsWith('**Definition:**')) {
        currentDef = line.replaceFirst('**Definition:**', '').trim();
      } else if (line.startsWith('**Examples:**')) {
        currentEx = line.replaceFirst('**Examples:**', '').trim();
      } else if (line.startsWith('• **')) {
        // Full glossary line: • **Term**: Definition
        final match = RegExp(r'• \*\*(.+?)\*\*:\s*(.*)').firstMatch(line);
        if (match != null) {
          entries.add({'term': match.group(1)!, 'definition': match.group(2)!});
        }
      }
    }

    if (currentTerm != null && entries.isEmpty) {
      entries.add({'term': currentTerm, 'definition': currentDef ?? '', 'example': currentEx ?? ''});
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'GLOSSARY${entries.length > 1 ? ' (${entries.length} terms)' : ''}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['term'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry['definition'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                    ),
                    if (entry['example']?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry['example']!,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class SummaryMessageWidget extends StatelessWidget {
  const SummaryMessageWidget({required this.text, super.key});
  final String text;

  Map<String, String> get _parsed {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    String chapter = '';
    final contentLines = <String>[];
    bool pastHeader = false;
    for (final line in lines) {
      if (line.startsWith('**Chapter:**')) {
        chapter = line.replaceFirst('**Chapter:**', '').trim();
        pastHeader = true;
      } else if (pastHeader && !line.startsWith('**📋')) {
        contentLines.add(line);
      }
    }
    return {'chapter': chapter, 'content': contentLines.join('\n')};
  }

  @override
  Widget build(BuildContext context) {
    final data = _parsed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'CHAPTER SUMMARY',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (data['chapter']?.isNotEmpty == true)
            Text(
              data['chapter']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (data['content']?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              data['content']!,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKSHEET WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class WorksheetMessageWidget extends StatelessWidget {
  const WorksheetMessageWidget({required this.text, super.key});
  final String text;

  Map<String, String> get _parsed {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    String topic = '';
    final contentLines = <String>[];
    bool pastHeader = false;
    for (final line in lines) {
      if (line.startsWith('**Topic:**')) {
        topic = line.replaceFirst('**Topic:**', '').trim();
        pastHeader = true;
      } else if (pastHeader && !line.startsWith('**📝')) {
        contentLines.add(line);
      }
    }
    return {'topic': topic, 'content': contentLines.join('\n\n')};
  }

  @override
  Widget build(BuildContext context) {
    final data = _parsed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0277BD), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'WORKSHEET',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (data['topic']?.isNotEmpty == true)
            Text(
              data['topic']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (data['content']?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              data['content']!,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMART ASSET MESSAGE RENDERER
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the correct widget for a given assistant message.
///
/// Usage in chat list builder:
///   `AssetMessageRenderer.render(message.text)`
class AssetMessageRenderer {
  const AssetMessageRenderer._();

  static Widget render(String text) {
    final type = detectAssetType(text);
    switch (type) {
      case AssetMessageType.flashcard:
        return FlashcardMessageWidget(text: text);
      case AssetMessageType.quiz:
        return QuizMessageWidget(text: text);
      case AssetMessageType.glossary:
        return GlossaryMessageWidget(text: text);
      case AssetMessageType.summary:
        return SummaryMessageWidget(text: text);
      case AssetMessageType.worksheet:
        return WorksheetMessageWidget(text: text);
      case AssetMessageType.plain:
        return const SizedBox.shrink(); // Caller should handle plain text
    }
  }

  /// Whether [text] represents a structured asset that should use a custom widget.
  static bool isAssetMessage(String text) {
    return detectAssetType(text) != AssetMessageType.plain;
  }
}
