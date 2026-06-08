import 'package:flutter/material.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../experiment/builder/storage/builder_draft_manager.dart';
import 'teacher_review_screen.dart';
import '../../shared/presentation/widgets/empty_state_card.dart';

class TeacherDashboardScreen extends StatelessWidget {
  final TeacherDashboardController controller;
  final BuilderDraftManager draftManager;

  const TeacherDashboardScreen({
    super.key,
    required this.controller,
    required this.draftManager,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sessions'),
              Tab(text: 'Assignments'),
              Tab(text: 'Submissions'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return TabBarView(
              children: [
                _buildSessionsTab(context),
                _buildAssignmentsTab(context),
                _buildSubmissionsTab(context),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _createNewSession(context),
          tooltip: 'New Session',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSessionsTab(BuildContext context) {
    if (controller.activeSessions.isEmpty) {
      return const EmptyStateCard(
        title: 'No Active Sessions',
        message: 'Tap the + button to create a new classroom session.',
        icon: Icons.school_outlined,
      );
    }
    return ListView.builder(
      itemExtent: 88.0,
      itemCount: controller.activeSessions.length,
      itemBuilder: (context, index) {
        final session = controller.activeSessions[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.school, color: Colors.blue),
            title: Text(session.topic),
            subtitle: Text('ID: ${session.id} | Students: ${session.connectedStudents.length}'),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Close Session',
              onPressed: () => controller.closeSession(session.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => _distributeNewAssignment(context),
            icon: const Icon(Icons.send),
            label: const Text('Distribute Draft Experiment'),
          ),
        ),
        const Divider(),
        Expanded(
          child: controller.assignments.isEmpty
              ? const EmptyStateCard(
                  title: 'No Assignments',
                  message: 'Distribute a draft experiment to a session.',
                  icon: Icons.assignment_outlined,
                )
              : ListView.builder(
                  itemExtent: 72.0,
                  itemCount: controller.assignments.length,
                  itemBuilder: (context, index) {
                    final assign = controller.assignments[index];
                    return ListTile(
                      leading: const Icon(Icons.assignment),
                      title: Text(assign.title),
                      subtitle: Text('Session: ${assign.sessionId}'),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSubmissionsTab(BuildContext context) {
    if (controller.submissions.isEmpty) {
      return const EmptyStateCard(
        title: 'No Submissions',
        message: 'Waiting for students to complete their assignments.',
        icon: Icons.inbox_outlined,
      );
    }
    return ListView.builder(
      itemExtent: 72.0,
      itemCount: controller.submissions.length,
      itemBuilder: (context, index) {
        final sub = controller.submissions[index];
        return ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text('${sub.studentName} - ${sub.status}'),
          subtitle: Text('Assignment: ${sub.assignmentId}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TeacherReviewScreen(submission: sub),
            ));
          },
        );
      },
    );
  }

  void _createNewSession(BuildContext context) {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Session'),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(hintText: 'Topic (e.g. Physics Lab B)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (tc.text.isNotEmpty) {
                controller.createSession(tc.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _distributeNewAssignment(BuildContext context) {
    if (controller.activeSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a session first!')));
      return;
    }
    if (draftManager.drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No drafts available to distribute!')));
      return;
    }

    String? selectedSession = controller.activeSessions.first.id;
    String? selectedDraft = draftManager.drafts.first.draftId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Distribute Assignment'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedSession,
                isExpanded: true,
                items: controller.activeSessions.map((s) => DropdownMenuItem(value: s.id, child: Text(s.topic))).toList(),
                onChanged: (v) => setState(() => selectedSession = v),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedDraft,
                isExpanded: true,
                items: draftManager.drafts.map((d) => DropdownMenuItem(value: d.draftId, child: Text(d.title))).toList(),
                onChanged: (v) => setState(() => selectedDraft = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (selectedSession != null && selectedDraft != null) {
                final draft = draftManager.drafts.firstWhere((d) => d.draftId == selectedDraft);
                controller.distributeExperiment(selectedSession!, draft.title, draft.manifest);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Distributed!')));
              }
            },
            child: const Text('Distribute'),
          ),
        ],
      ),
    );
  }
}
