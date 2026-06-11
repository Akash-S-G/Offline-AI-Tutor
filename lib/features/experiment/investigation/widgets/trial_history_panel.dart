import 'package:flutter/material.dart';

import '../comparison/trial_comparison_engine.dart';
import '../conclusions/conclusion_engine.dart';
import '../models/trial_comparison.dart';
import '../trials/experiment_trial_manager.dart';

class TrialHistoryPanel extends StatefulWidget {
  final ExperimentTrialManager trialManager;
  final TrialComparisonEngine comparisonEngine;
  final ConclusionEngine conclusionEngine;
  final ValueChanged<String>? onFeedback;

  const TrialHistoryPanel({
    super.key,
    required this.trialManager,
    required this.comparisonEngine,
    required this.conclusionEngine,
    this.onFeedback,
  });

  @override
  State<TrialHistoryPanel> createState() => _TrialHistoryPanelState();
}

class _TrialHistoryPanelState extends State<TrialHistoryPanel> {
  TrialComparison? _comparison;
  String? _conclusion;
  String? _selectedTrialId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.trialManager,
      builder: (context, _) {
        final trials = widget.trialManager.trials;
        final selected = _selectedTrialId == null
            ? null
            : widget.trialManager.loadTrial(_selectedTrialId!);
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _StatusCard(
              trials: trials.length,
              comparisonReady: trials.length >= 2,
              conclusionReady: _conclusion != null,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: widget.trialManager.isRunning
                      ? null
                      : () {
                          final trial = widget.trialManager.startTrial();
                          widget.onFeedback?.call(
                            'Trial ${trial.trialNumber} started',
                          );
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run Trial'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.trialManager.isRunning
                      ? () {
                          final trial = widget.trialManager.stopTrial();
                          if (trial != null) {
                            widget.onFeedback?.call(
                              'Trial ${trial.trialNumber} saved',
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Trial'),
                ),
                OutlinedButton.icon(
                  onPressed: trials.length < 2 ? null : _compareLatest,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Compare'),
                ),
                OutlinedButton.icon(
                  onPressed: trials.length < 2 ? null : _generateConclusion,
                  icon: const Icon(Icons.summarize_outlined),
                  label: const Text('Conclude'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (trials.isEmpty)
              const Center(
                child: Text('Run and save trials to compare results.'),
              )
            else
              ...trials.map((trial) {
                final selected = trial.trialId == _selectedTrialId;
                return Card(
                  color: selected ? const Color(0xFFEFF6FF) : Colors.white,
                  child: ListTile(
                    selected: selected,
                    leading: const Icon(Icons.science_outlined),
                    title: Text('Trial ${trial.trialNumber}'),
                    subtitle: Text(
                      'Duration ${trial.duration.inSeconds}s | '
                      '${trial.parameterValues.length} parameters | '
                      '${trial.measurements.length} measurements',
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete Trial',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          widget.trialManager.deleteTrial(trial.trialId),
                    ),
                    onTap: () =>
                        setState(() => _selectedTrialId = trial.trialId),
                  ),
                );
              }),
            if (selected != null) ...[
              const SizedBox(height: 8),
              _SnapshotCard(
                trialNumber: selected.trialNumber,
                data: selected.toJson(),
              ),
            ],
            if (_comparison != null) ...[
              const SizedBox(height: 12),
              _ComparisonCard(comparison: _comparison!),
            ],
            if (_conclusion != null) ...[
              const SizedBox(height: 12),
              _ConclusionCard(conclusion: _conclusion!),
            ],
          ],
        );
      },
    );
  }

  void _compareLatest() {
    final trials = widget.trialManager.trials;
    final comparison = widget.comparisonEngine.compare(
      trials[trials.length - 2],
      trials.last,
    );
    widget.trialManager.world.eventBus.emit(
      widget.trialManager.createEvent('ComparisonCompleted', {
        'firstTrialId': comparison.first.trialId,
        'secondTrialId': comparison.second.trialId,
      }),
    );
    setState(() => _comparison = comparison);
    widget.onFeedback?.call('Comparison ready');
  }

  void _generateConclusion() {
    final trials = widget.trialManager.trials;
    final comparisons = widget.comparisonEngine.compareSeries(trials);
    final conclusion = widget.conclusionEngine.generate(
      trials: trials,
      comparisons: comparisons,
    );
    widget.trialManager.world.eventBus.emit(
      widget.trialManager.createEvent('ConclusionGenerated', {
        'trialCount': trials.length,
        'conclusion': conclusion,
      }),
    );
    setState(() {
      _comparison = comparisons.isEmpty ? _comparison : comparisons.last;
      _conclusion = conclusion;
    });
    widget.onFeedback?.call('Conclusion generated');
  }
}

class _StatusCard extends StatelessWidget {
  final int trials;
  final bool comparisonReady;
  final bool conclusionReady;

  const _StatusCard({
    required this.trials,
    required this.comparisonReady,
    required this.conclusionReady,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Investigation',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('Trials: $trials'),
            Text('Comparison: ${comparisonReady ? 'Ready' : 'Needs 2 trials'}'),
            Text('Conclusion: ${conclusionReady ? 'Generated' : 'Needed'}'),
          ],
        ),
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final int trialNumber;
  final Map<String, dynamic> data;

  const _SnapshotCard({required this.trialNumber, required this.data});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Trial $trialNumber Snapshot'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        Text(
          data.toString(),
          maxLines: 8,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final TrialComparison comparison;

  const _ComparisonCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trial ${comparison.first.trialNumber} vs Trial ${comparison.second.trialNumber}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...comparison.results.map((result) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '${result.parameter}: ${result.trialA} -> ${result.trialB} '
                  '(${result.difference})',
                ),
              );
            }),
            if (comparison.results.isEmpty) const Text('No differences found.'),
            const SizedBox(height: 6),
            Text(comparison.summary),
          ],
        ),
      ),
    );
  }
}

class _ConclusionCard extends StatelessWidget {
  final String conclusion;

  const _ConclusionCard({required this.conclusion});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          conclusion,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
