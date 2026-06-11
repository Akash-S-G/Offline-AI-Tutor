import 'package:flutter/material.dart';

import '../conclusions/conclusion_generator.dart';
import '../models/investigation_timeline_entry.dart';
import '../predictions/prediction_store.dart';
import '../trials/experiment_trial_manager.dart';
import '../engine/investigation_timeline.dart';

class InvestigationWorkspace extends StatefulWidget {
  final ExperimentTrialManager trialManager;
  final PredictionStore predictionStore;
  final ConclusionGenerator conclusionGenerator;
  final InvestigationTimeline timeline;
  final ValueChanged<String>? onFeedback;

  const InvestigationWorkspace({
    super.key,
    required this.trialManager,
    required this.predictionStore,
    required this.conclusionGenerator,
    required this.timeline,
    this.onFeedback,
  });

  @override
  State<InvestigationWorkspace> createState() => _InvestigationWorkspaceState();
}

class _InvestigationWorkspaceState extends State<InvestigationWorkspace> {
  final TextEditingController _predictionController = TextEditingController();
  String? _conclusion;

  @override
  void dispose() {
    _predictionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.trialManager,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.science_outlined,
                      color: Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Investigation',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text('Trials: ${widget.trialManager.trialCount}'),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _predictionController,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Prediction',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _submitPrediction,
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Predict'),
                    ),
                    FilledButton.icon(
                      onPressed: widget.trialManager.isRunning
                          ? null
                          : () {
                              final trial = widget.trialManager.startTrial();
                              widget.timeline.add(
                                type: InvestigationTimelineType.trial,
                                title: 'Trial ${trial.trialNumber}',
                                description: 'Trial started.',
                              );
                              widget.onFeedback?.call(
                                'Trial ${trial.trialNumber} started',
                              );
                            },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run'),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.trialManager.isRunning
                          ? () {
                              final trial = widget.trialManager.stopTrial();
                              if (trial != null) {
                                widget.timeline.add(
                                  type: InvestigationTimelineType.trial,
                                  title: 'Trial ${trial.trialNumber} saved',
                                  description:
                                      'Duration ${trial.duration.inSeconds}s',
                                );
                                widget.onFeedback?.call(
                                  'Trial ${trial.trialNumber} saved',
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.pause),
                      label: const Text('Save'),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.trialManager.resetTrial,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset'),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.trialManager.trials.length < 2
                          ? null
                          : _generateConclusion,
                      icon: const Icon(Icons.summarize_outlined),
                      label: const Text('Conclude'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Prediction: ${widget.predictionStore.hasPrediction ? 'submitted' : 'needed'} | '
                  'Observation: ${widget.trialManager.trials.isEmpty ? 'needed' : 'captured'} | '
                  'Conclusion: ${_conclusion == null ? 'needed' : 'ready'}',
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                if (_conclusion != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _conclusion!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitPrediction() {
    final text = _predictionController.text.trim();
    if (text.isEmpty) return;
    final entry = widget.predictionStore.submit(
      prompt: 'What do you predict will happen?',
      prediction: text,
    );
    widget.timeline.add(
      type: InvestigationTimelineType.prediction,
      title: 'Prediction',
      description: entry.prediction,
    );
    widget.onFeedback?.call('Prediction saved');
  }

  void _generateConclusion() {
    final conclusion = widget.conclusionGenerator.generate(
      widget.trialManager.trials,
    );
    setState(() => _conclusion = conclusion);
    widget.timeline.add(
      type: InvestigationTimelineType.conclusion,
      title: 'Conclusion',
      description: conclusion,
    );
    widget.onFeedback?.call('Conclusion generated');
  }
}
