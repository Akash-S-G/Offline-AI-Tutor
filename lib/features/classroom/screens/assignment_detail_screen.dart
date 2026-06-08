import 'package:flutter/material.dart';
import '../models/classroom_assignment.dart';
import '../controllers/student_dashboard_controller.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final ClassroomAssignment assignment;
  final StudentDashboardController controller;

  const AssignmentDetailScreen({super.key, required this.assignment, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool isSubmitted = controller.isSubmitted(assignment.id);

    return Scaffold(
      appBar: AppBar(title: Text(assignment.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSubmitted)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(8),
                color: Colors.green.shade100,
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('You have submitted this assignment.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(assignment.instructions),
            const Divider(height: 32),
            Text('Due Date: ${assignment.dueDate.toString().substring(0, 16)}'),
            const SizedBox(height: 8),
            Text('Execution Modes: ${assignment.executionModes.join(", ")}'),
            const SizedBox(height: 8),
            Text('Required Sensors: ${assignment.requiredSensors.join(", ")}'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSubmitted ? null : () async {
                  // Simulate running an experiment and generating a result
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating Experiment Run...')));
                  await Future.delayed(const Duration(seconds: 2));
                  await controller.simulateRunAndSubmit(assignment.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully Submitted!')));
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run & Submit Experiment'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
