import 'package:flutter/material.dart';
import '../controllers/student_dashboard_controller.dart';
import 'assignment_detail_screen.dart';
import '../../shared/presentation/widgets/empty_state_card.dart';

class StudentDashboardScreen extends StatelessWidget {
  final StudentDashboardController controller;

  const StudentDashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Dashboard'),
          bottom: const TabBar(
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
      itemExtent: 88.0,
      itemCount: controller.assignments.length,
      itemBuilder: (context, index) {
        final assign = controller.assignments[index];
        final submitted = controller.isSubmitted(assign.id);
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: Icon(submitted ? Icons.check_circle : Icons.assignment, color: submitted ? Colors.green : Colors.orange),
            title: Text(assign.title),
            subtitle: Text('Due: ${assign.dueDate.toString().substring(0, 16)}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AssignmentDetailScreen(assignment: assign, controller: controller),
              ));
            },
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
        icon: Icons.done_all,
      );
    }
    return ListView.builder(
      itemExtent: 72.0,
      itemCount: controller.mySubmissions.length,
      itemBuilder: (context, index) {
        final sub = controller.mySubmissions[index];
        return ListTile(
          leading: const Icon(Icons.task_alt, color: Colors.green),
          title: Text('Assignment: ${sub.assignmentId}'),
          subtitle: Text('Score: ${sub.resultMetrics['score']} | Status: ${sub.status}'),
        );
      },
    );
  }
}
