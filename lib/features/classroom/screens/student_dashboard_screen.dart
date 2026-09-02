import 'package:flutter/material.dart';
import '../controllers/student_dashboard_controller.dart';
import 'assignment_detail_screen.dart';
import '../../shared/presentation/widgets/empty_state_card.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';

class StudentDashboardScreen extends StatelessWidget {
  final StudentDashboardController controller;

  const StudentDashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: IDPColors.background,
        appBar: AppBar(
          title: const Text('Student Dashboard', style: IDPTypography.titleMedium),
          backgroundColor: IDPColors.surface,
          foregroundColor: IDPColors.onSurface,
          elevation: 0,
          bottom: const TabBar(
            labelColor: IDPColors.primary,
            unselectedLabelColor: IDPColors.textSecondary,
            indicatorColor: IDPColors.primary,
            tabs: [
              Tab(text: 'Assignments'),
              Tab(text: 'My Submissions'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return TabBarView(
              children: [
                _buildAssignmentsTab(context),
                _buildSubmissionsTab(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab(BuildContext context) {
    if (controller.assignments.isEmpty) {
      return const EmptyStateCard(
        title: 'No Assignments',
        message: 'No available assignments. Waiting for Teacher...',
        icon: Icons.assignment_turned_in_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(IDPSpacing.md),
      itemCount: controller.assignments.length,
      itemBuilder: (context, index) {
        final assign = controller.assignments[index];
        final submitted = controller.isSubmitted(assign.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: IDPSpacing.sm),
          child: IDPCard(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AssignmentDetailScreen(assignment: assign, controller: controller),
              ));
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: submitted ? IDPColors.secondaryContainer : IDPColors.primaryContainer,
                  child: Icon(
                    submitted ? Icons.check_circle_rounded : Icons.assignment_rounded,
                    color: submitted ? IDPColors.secondary : IDPColors.primary,
                  ),
                ),
                const SizedBox(width: IDPSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assign.title, style: IDPTypography.titleSmall),
                      const SizedBox(height: IDPSpacing.xs / 2),
                      Text(
                        'Due: ${assign.dueDate.toString().substring(0, 16)}',
                        style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: IDPColors.textHint),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionsTab(BuildContext context) {
    if (controller.mySubmissions.isEmpty) {
      return const EmptyStateCard(
        title: 'No Submissions',
        message: 'You have not submitted anything yet.',
        icon: Icons.done_all_rounded,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(IDPSpacing.md),
      itemCount: controller.mySubmissions.length,
      itemBuilder: (context, index) {
        final sub = controller.mySubmissions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: IDPSpacing.sm),
          child: IDPCard(
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: IDPColors.secondaryContainer,
                  child: Icon(Icons.task_alt_rounded, color: IDPColors.secondary),
                ),
                const SizedBox(width: IDPSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assignment: ${sub.assignmentId}', style: IDPTypography.titleSmall),
                      const SizedBox(height: IDPSpacing.xs / 2),
                      Text(
                        'Score: ${sub.resultMetrics['score']} | Status: ${sub.status}',
                        style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

