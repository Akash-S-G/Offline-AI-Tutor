import '../../runtime/experiment_state/runtime_experiment_snapshot.dart';
import '../../runtime/runtime_world.dart';

class TrialSnapshot {
  final Map<String, dynamic> variables;
  final List<Map<String, dynamic>> objects;
  final Map<String, List<Map<String, dynamic>>> measurements;
  final List<Map<String, dynamic>> observations;
  final List<Map<String, dynamic>> graphs;
  final Map<String, dynamic> questionAnswers;

  const TrialSnapshot({
    required this.variables,
    required this.objects,
    required this.measurements,
    required this.observations,
    required this.graphs,
    this.questionAnswers = const {},
  });

  factory TrialSnapshot.fromRuntimeSnapshot(
    RuntimeExperimentSnapshot snapshot,
  ) {
    return TrialSnapshot(
      variables: snapshot.variables.map(
        (id, variable) => MapEntry(id, variable.value),
      ),
      objects: snapshot.objectStates
          .map((objectState) => objectState.toJson())
          .toList(growable: false),
      measurements: const {},
      observations: const [],
      graphs: snapshot.objectStates
          .where(
            (state) => {
              'lineGraph',
              'scatterPlot',
              'barChart',
              'oscilloscope',
              'spectrumAnalyzer',
            }.contains(state.objectType),
          )
          .map((state) => state.toJson())
          .toList(growable: false),
    );
  }

  factory TrialSnapshot.fromWorld(
    RuntimeWorld world, {
    Map<String, dynamic> questionAnswers = const {},
  }) {
    return TrialSnapshot(
      variables: world.variables.allRuntimeVariables.map(
        (id, variable) => MapEntry(id, variable.value),
      ),
      objects: world.objects.allObjectStates
          .map((objectState) => objectState.toJson())
          .toList(growable: false),
      measurements: world.measurementStore.exportMeasurements().map(
        (id, measurements) => MapEntry(
          id,
          measurements
              .map((measurement) => measurement.toJson())
              .toList(growable: false),
        ),
      ),
      observations: world.observationStore
          .getObservations()
          .map((observation) => observation.toJson())
          .toList(growable: false),
      graphs: world.objects.allObjectStates
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
          .map((state) => state.toJson())
          .toList(growable: false),
      questionAnswers: questionAnswers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variables': variables,
      'objects': objects,
      'measurements': measurements,
      'observations': observations,
      'graphs': graphs,
      'questionAnswers': questionAnswers,
    };
  }
}
