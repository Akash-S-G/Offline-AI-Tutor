import 'package:flutter/material.dart';
import '../models/classroom_submission.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';

class TeacherReviewScreen extends StatelessWidget {
  final ClassroomSubmission submission;

  const TeacherReviewScreen({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Submission Review', style: IDPTypography.titleMedium),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(IDPSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IDPCard(
              backgroundColor: IDPColors.primaryContainer.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student: ${submission.studentName}', style: IDPTypography.titleMedium),
                  const SizedBox(height: IDPSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: IDPColors.secondary, size: 18),
                      const SizedBox(width: IDPSpacing.xs),
                      Text('Status: ${submission.status}', style: IDPTypography.bodyMedium.copyWith(color: IDPColors.secondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: IDPSpacing.md),
            IDPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Completed At: ${submission.completionTime}', style: IDPTypography.bodySmall),
                  const SizedBox(height: IDPSpacing.xs),
                  Text('Submitted At: ${submission.submissionTime}', style: IDPTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: IDPSpacing.md),
            const IDPSectionHeader(title: 'Metrics'),
            const SizedBox(height: IDPSpacing.sm),
            IDPCard(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score: ${submission.resultMetrics['score'] ?? 0}', style: IDPTypography.titleSmall),
                    const SizedBox(height: IDPSpacing.xs),
                    Text('Time Spent: ${submission.resultMetrics['timeSpentSeconds'] ?? 0} seconds', style: IDPTypography.bodyMedium.copyWith(color: IDPColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

