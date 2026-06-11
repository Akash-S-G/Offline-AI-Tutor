enum InvestigationStepType {
  prediction,
  run,
  observation,
  comparison,
  conclusion,
}

class InvestigationStep {
  final String id;
  final InvestigationStepType type;
  final String title;
  final String instruction;

  const InvestigationStep({
    required this.id,
    required this.type,
    required this.title,
    required this.instruction,
  });

  static const defaults = [
    InvestigationStep(
      id: 'prediction',
      type: InvestigationStepType.prediction,
      title: 'Predict',
      instruction: 'Make a prediction before running the experiment.',
    ),
    InvestigationStep(
      id: 'run',
      type: InvestigationStepType.run,
      title: 'Run',
      instruction: 'Run a trial and observe what changes.',
    ),
    InvestigationStep(
      id: 'observe',
      type: InvestigationStepType.observation,
      title: 'Observe',
      instruction: 'Record your measurements and observations.',
    ),
    InvestigationStep(
      id: 'compare',
      type: InvestigationStepType.comparison,
      title: 'Compare',
      instruction: 'Compare trials to identify a pattern.',
    ),
    InvestigationStep(
      id: 'conclude',
      type: InvestigationStepType.conclusion,
      title: 'Conclude',
      instruction: 'Write a conclusion from the evidence.',
    ),
  ];
}
