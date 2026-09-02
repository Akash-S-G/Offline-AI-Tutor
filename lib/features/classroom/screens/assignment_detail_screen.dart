import 'package:flutter/material.dart';
import '../models/classroom_assignment.dart';
import '../controllers/student_dashboard_controller.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final ClassroomAssignment assignment;
  final StudentDashboardController controller;

  const AssignmentDetailScreen({super.key, required this.assignment, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool isSubmitted = controller.isSubmitted(assignment.id);

    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: Text(assignment.title, style: IDPTypography.titleMedium),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(IDPSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSubmitted) ...[
              Container(
                margin: const EdgeInsets.only(bottom: IDPSpacing.md),
                padding: const EdgeInsets.all(IDPSpacing.md),
                decoration: BoxDecoration(
                  color: IDPColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(IDPRadius.defaultRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: IDPColors.secondary),
                    const SizedBox(width: IDPSpacing.sm),
                    Text(
                      'You have submitted this assignment.',
                      style: IDPTypography.bodyMedium.copyWith(color: IDPColors.onSecondaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const IDPSectionHeader(title: 'Instructions'),
            const SizedBox(height: IDPSpacing.sm),
            IDPCard(
              child: SizedBox(
                width: double.infinity,
                child: Text(assignment.instructions, style: IDPTypography.bodyMedium),
              ),
            ),
            const SizedBox(height: IDPSpacing.md),
            IDPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Due Date: ${assignment.dueDate.toString().substring(0, 16)}', style: IDPTypography.bodyMedium),
                  const SizedBox(height: IDPSpacing.xs),
                  Text('Execution Modes: ${assignment.executionModes.join(", ")}', style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary)),
                  const SizedBox(height: IDPSpacing.xs),
                  Text('Required Sensors: ${assignment.requiredSensors.join(", ")}', style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: IDPSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSubmitted ? null : () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating Experiment Run...')));
                  await Future.delayed(const Duration(seconds: 2));
                  await controller.simulateRunAndSubmit(assignment.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully Submitted!')));
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Run & Submit Experiment', style: IDPTypography.labelLarge),
                style: FilledButton.styleFrom(
                  backgroundColor: IDPColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: IDPSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IDPRadius.defaultRadius)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

