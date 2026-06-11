import '../../runtime/runtime_world.dart';
import 'completion_condition.dart';
import 'experiment_step.dart';
import 'step_type.dart';

class RuntimeExperience {
  final String id;
  final String title;
  final String description;
  final String objective;
  final List<ExperimentStep> steps;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> completionCriteria;
  final Map<String, dynamic> metadata;

  const RuntimeExperience({
    required this.id,
    required this.title,
    required this.description,
    required this.objective,
    required this.steps,
    this.questions = const [],
    this.completionCriteria = const [],
    this.metadata = const {},
  });

  factory RuntimeExperience.fromJson(Map<String, dynamic> json) {
    return RuntimeExperience(
      id: json['id']?.toString() ?? 'experience',
      title: json['title']?.toString() ?? 'Experiment',
      description: json['description']?.toString() ?? '',
      objective: json['objective']?.toString() ?? 'Explore the experiment.',
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (step) => ExperimentStep.fromJson(Map<String, dynamic>.from(step)),
          )
          .toList(growable: false),
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
      completionCriteria:
          (json['completionCriteria'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }

  factory RuntimeExperience.fromWorld(RuntimeWorld world) {
    final rawExperience = world.metadata['experience'];
    if (rawExperience is Map) {
      final experience = RuntimeExperience.fromJson(
        Map<String, dynamic>.from(rawExperience),
      );
      if (experience.steps.isNotEmpty) return experience;
      return experience.copyWith(steps: _defaultSteps(world));
    }
    return RuntimeExperience(
      id: world.metadata['sceneId']?.toString() ?? 'experience',
      title:
          world.metadata['name']?.toString() ??
          world.metadata['title']?.toString() ??
          'Experiment',
      description:
          world.metadata['description']?.toString() ??
          'Use the controls, observe the simulation, and record what you learn.',
      objective:
          world.metadata['objective']?.toString() ??
          'Explore how changing variables affects the experiment.',
      steps: _defaultSteps(world),
      metadata: Map<String, dynamic>.from(world.metadata),
    );
  }

  RuntimeExperience copyWith({List<ExperimentStep>? steps}) {
    return RuntimeExperience(
      id: id,
      title: title,
      description: description,
      objective: objective,
      steps: steps ?? this.steps,
      questions: questions,
      completionCriteria: completionCriteria,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'objective': objective,
      'steps': steps.map((step) => step.toJson()).toList(),
      'questions': questions,
      'completionCriteria': completionCriteria,
      'metadata': metadata,
    };
  }

  static List<ExperimentStep> _defaultSteps(RuntimeWorld world) {
    final controls = world.objects.allObjectStates
        .where(
          (state) => {'slider', 'button', 'toggle'}.contains(state.objectType),
        )
        .toList(growable: false);
    final graphs = world.objects.allObjectStates
        .where(
          (state) => {
            'lineGraph',
            'scatterPlot',
            'barChart',
            'oscilloscope',
            'spectrumAnalyzer',
            'vectorVisualizer',
          }.contains(state.objectType),
        )
        .toList(growable: false);
    return [
      const ExperimentStep(
        id: 'observe_simulation',
        title: 'Observe',
        instruction: 'Look at the simulation and identify what changes.',
        type: StepType.instruction,
        completionCondition: CustomCondition(eventName: 'ExperimentStarted'),
      ),
      if (controls.isNotEmpty)
        const ExperimentStep(
          id: 'use_control',
          title: 'Use a Control',
          instruction: 'Change one control and watch the result.',
          type: StepType.interaction,
          completionCondition: ControlUsedCondition(),
        ),
      const ExperimentStep(
        id: 'record_observation',
        title: 'Record Observation',
        instruction: 'Record one observation from the experiment.',
        type: StepType.observation,
        completionCondition: ObservationCondition(),
      ),
      if (graphs.isNotEmpty)
        const ExperimentStep(
          id: 'analyze_graph',
          title: 'Analyze',
          instruction: 'Open or update a graph and compare the data.',
          type: StepType.analysis,
          completionCondition: GraphViewedCondition(),
        ),
      const ExperimentStep(
        id: 'complete_experiment',
        title: 'Complete',
        instruction: 'Finish the experiment when your observations are done.',
        type: StepType.completion,
        completionCondition: CustomCondition(eventName: 'ExperimentCompleted'),
      ),
    ];
  }
}
