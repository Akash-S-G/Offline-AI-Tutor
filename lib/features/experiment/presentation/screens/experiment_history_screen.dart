// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

class ExperimentHistoryScreen extends StatefulWidget {
  final String studentId;

  const ExperimentHistoryScreen({super.key, required this.studentId});

  @override
  State<ExperimentHistoryScreen> createState() => _ExperimentHistoryScreenState();
}

class _ExperimentHistoryScreenState extends State<ExperimentHistoryScreen> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _runs = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    print('[EXPERIMENT_UI] HISTORY_LOAD');
    setState(() => _isLoading = true);

    // Placeholder for GET /experiment-runs/student/{student_id}
    await Future.delayed(const Duration(seconds: 1));

    _runs.add({
      'name': 'Simple Pendulum',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'duration': '5m 30s',
      'status': 'completed',
      'mode': 'Simulation',
      'score': 85,
    });

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Experiments'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _runs.length,
              itemBuilder: (context, index) {
                final run = _runs[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(run['name']),
                  subtitle: Text('${run['mode']} • ${run['duration']}'),
                  trailing: Text(
                    '${run['score']}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
            ),
    );
  }
}
