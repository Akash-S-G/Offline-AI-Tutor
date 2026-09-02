import 'package:flutter/material.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';
import 'chapter_screen.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';

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
        : IDPColors.primary;

    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: Text(widget.subject.name, style: IDPTypography.titleMedium),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
      ),
      body: FutureBuilder<List<ChapterModel>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: IDPColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading chapters: ${snapshot.error}', style: IDPTypography.bodyMedium.copyWith(color: IDPColors.error)),
            );
          }

          final chapters = snapshot.data ?? [];

          if (chapters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.library_books_outlined,
                    size: 56,
                    color: IDPColors.textHint,
                  ),
                  const SizedBox(height: IDPSpacing.md),
                  const Text(
                    'No chapters available',
                    style: IDPTypography.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(IDPSpacing.md),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: IDPSpacing.sm),
                child: _ChapterCard(
                  chapter: chapter,
                  color: subjectColor,
                ),
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
    return IDPCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterScreen(chapter: chapter),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  '${chapter.sequenceNumber}',
                  style: IDPTypography.titleSmall.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: IDPSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.name,
                      style: IDPTypography.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chapter.estimatedReadingMinutes != null) ...[
                      const SizedBox(height: IDPSpacing.xs / 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: IDPColors.textSecondary),
                          const SizedBox(width: IDPSpacing.xs / 2),
                          Text(
                            '${chapter.estimatedReadingMinutes} min',
                            style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: IDPColors.textHint),
            ],
          ),
          if (chapter.summary != null) ...[
            const SizedBox(height: IDPSpacing.sm),
            Text(
              chapter.summary!,
              style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

