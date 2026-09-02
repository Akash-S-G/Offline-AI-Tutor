import 'package:flutter/material.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';
import 'subject_screen.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';

/// Shows all subjects available for a specific grade
class GradeScreen extends StatefulWidget {
  final GradeModel grade;

  const GradeScreen({
    Key? key,
    required this.grade,
  }) : super(key: key);

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {
  late Future<List<SubjectModel>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = EducationalRepository.getSubjectsByGradeId(widget.grade.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: Text('Grade ${widget.grade.gradeNumber} - Subjects', style: IDPTypography.titleMedium),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
      ),
      body: FutureBuilder<List<SubjectModel>>(
        future: _subjectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: IDPColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading subjects: ${snapshot.error}', style: IDPTypography.bodyMedium.copyWith(color: IDPColors.error)),
            );
          }

          final subjects = snapshot.data ?? [];

          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 56,
                    color: IDPColors.textHint,
                  ),
                  const SizedBox(height: IDPSpacing.md),
                  const Text(
                    'No subjects available',
                    style: IDPTypography.titleMedium,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(IDPSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: IDPSpacing.md,
              mainAxisSpacing: IDPSpacing.md,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return _SubjectCard(subject: subject);
            },
          );
        },
      ),
    );
  }
}

/// Card widget for individual subject selection
class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final accentColor = subject.colorHex != null
        ? Color(subject.colorHex!)
        : IDPColors.primary;

    return IDPCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectScreen(subject: subject),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.15),
            radius: 24,
            child: Icon(Icons.book_rounded, size: 24, color: accentColor),
          ),
          const SizedBox(height: IDPSpacing.sm),
          Text(
            subject.name,
            textAlign: TextAlign.center,
            style: IDPTypography.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subject.description != null) ...[
            const SizedBox(height: IDPSpacing.xs / 2),
            Text(
              subject.description!,
              textAlign: TextAlign.center,
              style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

