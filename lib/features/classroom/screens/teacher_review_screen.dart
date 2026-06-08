import 'package:flutter/material.dart';
import '../models/classroom_submission.dart';

class TeacherReviewScreen extends StatelessWidget {
  final ClassroomSubmission submission;

  const TeacherReviewScreen({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submission Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${submission.studentName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Status: ${submission.status}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Completed At: ${submission.completionTime}'),
            Text('Submitted At: ${submission.submissionTime}'),
            const SizedBox(height: 16),
            const Text('Metrics:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score: ${submission.resultMetrics['score'] ?? 0}'),
                    Text('Time Spent: ${submission.resultMetrics['timeSpentSeconds'] ?? 0} seconds'),
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
