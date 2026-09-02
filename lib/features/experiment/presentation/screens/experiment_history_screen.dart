// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../../../core/theme/idp_colors.dart';
import '../../../../core/widgets/idp_core_widgets.dart';

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
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('My Experiments', style: IDPTypography.titleMedium),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: IDPColors.primary))
          : ListView.builder(
              padding: const EdgeInsets.all(IDPSpacing.md),
              itemCount: _runs.length,
              itemBuilder: (context, index) {
                final run = _runs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: IDPSpacing.sm),
                  child: IDPCard(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: IDPColors.primaryContainer,
                          child: Icon(Icons.science_rounded, color: IDPColors.primary),
                        ),
                        const SizedBox(width: IDPSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(run['name'], style: IDPTypography.titleSmall),
                              const SizedBox(height: IDPSpacing.xs / 2),
                              Text(
                                '${run['mode']} • ${run['duration']}',
                                style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${run['score']}%',
                          style: IDPTypography.titleMedium.copyWith(color: IDPColors.secondary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

