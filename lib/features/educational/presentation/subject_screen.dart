import 'package:flutter/material.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';
import 'chapter_screen.dart';

/// Shows all chapters available for a specific subject
class SubjectScreen extends StatefulWidget {
  final SubjectModel subject;

  const SubjectScreen({
    Key? key,
    required this.subject,
  }) : super(key: key);

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  late Future<List<ChapterModel>> _chaptersFuture;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = EducationalRepository.getChaptersBySubjectId(widget.subject.id!);
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = widget.subject.colorHex != null
        ? Color(widget.subject.colorHex!)
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: subjectColor,
      ),
      body: FutureBuilder<List<ChapterModel>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading chapters: ${snapshot.error}'),
            );
          }

          final chapters = snapshot.data ?? [];

          if (chapters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chapters available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return _ChapterCard(
                chapter: chapter,
                color: subjectColor,
              );
            },
          );
        },
      ),
    );
  }
}

/// Card widget for individual chapter selection
class _ChapterCard extends StatelessWidget {
  final ChapterModel chapter;
  final Color color;

  const _ChapterCard({
    required this.chapter,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChapterScreen(chapter: chapter),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        '${chapter.sequenceNumber}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (chapter.estimatedReadingMinutes != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${chapter.estimatedReadingMinutes} min',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
              if (chapter.summary != null) ...[
                const SizedBox(height: 12),
                Text(
                  chapter.summary!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
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
