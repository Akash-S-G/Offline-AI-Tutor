import 'package:flutter/material.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';
import 'grade_screen.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';

/// Curriculum home screen showing available grades
/// 
/// Entry point for offline educational learning.
/// Users select a grade to navigate through subjects → chapters → topics.
class CurriculumHomeScreen extends StatefulWidget {
  const CurriculumHomeScreen({Key? key}) : super(key: key);

  @override
  State<CurriculumHomeScreen> createState() => _CurriculumHomeScreenState();
}

class _CurriculumHomeScreenState extends State<CurriculumHomeScreen> {
  late Future<List<GradeModel>> _gradesFuture;

  @override
  void initState() {
    super.initState();
    _gradesFuture = EducationalRepository.getAllGrades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Offline Educational Learning', style: IDPTypography.titleMedium),
        centerTitle: true,
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
      ),
      body: FutureBuilder<List<GradeModel>>(
        future: _gradesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: IDPColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading grades: ${snapshot.error}', style: IDPTypography.bodyMedium.copyWith(color: IDPColors.error)),
            );
          }

          final grades = snapshot.data ?? [];

          if (grades.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 56,
                    color: IDPColors.textHint,
                  ),
                  const SizedBox(height: IDPSpacing.md),
                  const Text(
                    'No grades available',
                    style: IDPTypography.titleMedium,
                  ),
                  const SizedBox(height: IDPSpacing.xs),
                  Text(
                    'Download educational packs to get started',
                    style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(IDPSpacing.md),
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final grade = grades[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: IDPSpacing.sm),
                child: _GradeCard(grade: grade),
              );
            },
          );
        },
      ),
    );
  }
}

/// Card widget for individual grade selection
class _GradeCard extends StatelessWidget {
  final GradeModel grade;

  const _GradeCard({required this.grade});

  @override
  Widget build(BuildContext context) {
    return IDPCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GradeScreen(grade: grade),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: IDPColors.primaryContainer,
            child: Text(
              '${grade.gradeNumber}',
              style: IDPTypography.titleSmall.copyWith(color: IDPColors.onPrimaryContainer, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: IDPSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(grade.name, style: IDPTypography.titleSmall),
                if (grade.description != null) ...[
                  const SizedBox(height: IDPSpacing.xs / 2),
                  Text(
                    grade.description!,
                    style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: IDPColors.textHint),
        ],
      ),
    );
  }
}

